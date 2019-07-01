#!/usr/bin/env bash
# Drone CI kernel pipeline - changelog generation script

# Log all commands executed and exit on error
set -ve

# Get full comparison data from GitHub API
curl -sf https://api.github.com/repos/$DRONE_REPO_NAMESPACE/$DRONE_REPO_NAME/compare/$DRONE_COMMIT_BEFORE...$DRONE_COMMIT > github_compare.json

# Skip build if no code changes were made
CHANGED_FILES="$(cat github_compare.json | jq -r '.files[].filename | select(test("Documentation|README|COPYING|CREDITS|MAINTAINERS|samples") | not)')"

if [[ -z "$CHANGED_FILES" ]]; then
    touch skip_exec
    exit
fi

# Generate and show changelog based on commits
cat github_compare.json | jq -r '"​ ​ ​ ​ • " + ([.commits[] | select(.committer.login == "'$DRONE_REPO_OWNER'") | .commit.message | split("\n") | .[0]] | reverse | join("\n​ ​ ​ ​ • "))' | tee changelog.txt
