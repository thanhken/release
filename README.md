## @stindy/release

This Bash script automates the process of releasing new versions of your software project. It handles versioning, branch management, and optionally pushing changes to a remote repository. The script is designed to work across different operating systems including macOS and Windows.

## Features
- Increment version numbers automatically based on specified release type.
- Create a new release branch or work on an existing one.
- Optionally upgrade a specific package along with versioning.
- Commit changes and push to a remote repository.
- Open a pull request URL in your default browser (for GitHub repositories).

## Prerequisites
- Git installed on your system.
- Node.js and Yarn package manager installed if you're using JavaScript/Node.js projects.
- Proper configuration of your Git remote repository (GitHub, GitLab, etc.).

## Usage
```bash
release [options] <release_type>
```

## Options
- `-u | --upgrade <pkg>`: Upgrade a specific package along with versioning. Example: `-u @azoom/tomemiru-db@1.2.3`.
- `-r | --release <branch>`: Release branch name. Default: `main`.
- `-p | --push`: Push changes to the remote repository.
- `-h | --help`: Show help message.

## Release Types:
- `release`: Upgrade version in the develop branch.
- `release new`: Upgrade version in a new branch automatically created.
- `release <other_name>`: Upgrade version in an existing branch with a custom name.

## Notes
- This script assumes that your project follows sequential versioning.
- Make sure to review changes before pushing to the remote repository.
- This document powered by ChatGPT.