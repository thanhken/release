#!/bin/bash
set -e
############################# DEFINE ###############################
open_url() {
    local url=$1
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "$url"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows
        start "" "$url"
    else
        echo "Unsupported OS!"
    fi
}
echo_color() {
    if command -v tput >/dev/null 2>&1; then
        local reset=$(tput sgr0)
        local code=""
        local text="$(tput setaf 3)[AZ]$reset"
        while [[ $# -gt 0 ]]; do
            if [[ "$1" == "-n" ]]; then
                text=""
                shift
            fi
            if [[ "$1" == "-c" || "$1" == "--color" ]]; then
                color="$2"
                shift 2
            else
                case "$color" in
                    red)     code="1" ;;
                    green)   code="2" ;;
                    yellow)  code="3" ;;
                    *)       code="$color" ;;
                esac
                if [[ -n "$text" ]]; then
                    text+=" "
                fi
                if [[ "$color" == "none" ]]; then
                    text+="$1"
                else
                    color_text=$(tput setaf $code)
                    text+="$color_text$1$reset"
                fi
                shift
            fi
        done
        echo -e $text
    else
        echo -e "$@"
    fi
}
echo_helper() {
    echo_color -n -c none "Usage:"
    echo_color -n -c green "release" -c none "\t\t\t\tUpgrade version in the" -c yellow "develop" -c none "branch."
    echo_color -n -c green "release" -c yellow "new" -c none "\t\t\t\tUpgrade version in" -c yellow "a new branch" -c none "automatically created."
    echo_color -n -c green "release" -c yellow "<other_name>" -c none "\t\t\tUpgrade version in the" -c yellow "<other_name>" -c none "branch (existing branch)."
    echo_color -n -c none "\t[-u | --upgrade <pkg>]" -c none "\t\tAlso upgrade this package (ex:" -c yellow "@azoom/tomemiru-db@1.2.3" -c none ")"
    echo_color -n -c none "\t[-r | --release <branch>]" -c none "\tRelease branch name (default:" -c yellow "main" -c none ")"
    echo_color -n -c none "\t[-p | --push]" -c none "\t\t\tPush your changes to remote repository."
    echo_color -n -c none "\t[-h | --help]" -c none "\t\t\tShow help message."
}
####################################################################

max_patch=9
max_minor=9
release_type=$1
release_branch="main"
version_up_branch="develop"
upgrade_package=""
github_url=$(git remote get-url origin)
push_your_changes=false
if [[ $github_url == *".git" ]]; then
    github_url="${github_url%.git}"
fi

argument_parser() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--upgrade)
                upgrade_package="$2"
                shift 2
                ;;
            -r|--release)
                release_branch="$2"
                shift 2
                ;;
            -h|--help)
                echo_helper "$@"
                exit 0
                ;;
            -p|--push)
                push_your_changes=true
                shift
                ;;
            *)
                release_type=$1
                shift
                ;;
        esac
    done
}

argument_parser "$@"

############# CHECK GIT STATUS #############
if git diff --exit-code --quiet; then
    echo_color -c none "No files have changed."
else
    echo_color -c none  "Please commit your changes before continue."
    exit 0
fi

############# GET NEW VERSION #############
echo_color -c none "Checking out and pulling from" -c red $release_branch -c none "branch"
git fetch
git checkout $release_branch
git pull origin $release_branch

# Get the current version from package.json
current_version=$(node -p "require('./package.json').version")

# Extract major, minor, and patch version components
major_version=$(echo $current_version | cut -d. -f1)
minor_version=$(echo $current_version | cut -d. -f2)
patch_version=$(echo $current_version | cut -d. -f3)


# Initialize is_version_bumped variable
is_version_bumped=false

# Increment version and handle max value of 9
new_major_version=$((major_version))
if [ $patch_version -ge $max_patch ]; then
    new_minor_version=$((minor_version + 1))
    new_patch_version=0
    is_version_bumped=true
else
    new_minor_version=$((minor_version))
    new_patch_version=$((patch_version + 1))
    is_version_bumped=true
fi

if [ $new_minor_version -ge $max_minor ] && [ "$is_version_bumped" != "true" ]; then
    new_major_version=$((new_major_version + 1))
    new_minor_version=0
fi

# Set the new version
new_version="$new_major_version.$new_minor_version.$new_patch_version"

echo_color -c none "Current version:" -c yellow "v$current_version"
echo_color -c none "Release version:" -c green "v$new_version"

############## CHECKOUT VERSION UP BRANCH #############
if [ "$release_type" == "new" ]; then
    current_date=$(date "+%d%m%y-%H%M%S")
    version_up_branch="version-up-$current_date"
    git checkout -b $version_up_branch
    echo_color -c none "Created" -c green $version_up_branch -c none "branch"
else
    if [ -n "$release_type" ] && [[ ! "$release_type" == -* ]]; then
        version_up_branch=$release_type
    fi
    echo_color -c none "Checking out and pulling from" -c green $version_up_branch -c none "branch"
    git checkout $version_up_branch
    git pull origin $version_up_branch
fi


############## VERSION UP & COMMIT #############
echo_color -c none "Upgrade package to new version"
set +e
git tag -d "v$new_version"
set -e
yarn version --new-version $new_version

# Commit changes with version and :bookmark: message
echo_color -c none "Committing changes with new version..."
if [ -n "$upgrade_package" ]; then
    yarn upgrade $upgrade_package --exact
fi
git add .
git commit --amend -n -m ":bookmark: v$new_version"


############## PUSH #############
if $push_your_changes; then
    echo_color -c none "Pushing changes to remote repository..."
    if [ "$release_type" == "new" ]; then
        git push --set-upstream origin $version_up_branch
    else
        git push origin $version_up_branch
    fi

    url="$github_url/pull/new/$version_up_branch"
    open_url $url
    git checkout $release_branch
fi
echo_color -c none "Automation script completed successfully!"
