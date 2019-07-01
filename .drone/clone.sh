#!/usr/bin/env bash
# Drone CI kernel pipeline - Git clone script

# Log all commands executed and exit on error
set -ve

# Exit if skip marker is present
[[ -f "skip_exec" ]] && exit

# Use git protocol for speed
URL="$(sed 's|^https://|git://|' <<< $DRONE_GIT_HTTP_URL)"

# Perform shallow recursive clone
git clone --depth 1 --recursive --shallow-submodules --jobs 6 -b "$DRONE_BRANCH" --single-branch --no-tags "$URL" "$DRONE_REPO_NAME"

# Reset to target commit
cd "$DRONE_REPO_NAME"
git reset --hard "$DRONE_COMMIT"
