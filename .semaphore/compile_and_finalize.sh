#!/usr/bin/env bash
# The shebang is solely for shellcheck auditing; this script must be sourced
# for proper functionality.


#### COMPILE ####

# Load helpers
source setup.sh

# Update/initialize config
mc

# Disable native CPU-specific optimizations
scripts/config --file out/.config -d MNATIVE -e GENERIC_CPU

# Compile kernel
kmake


#### FINALIZE ####

# Generate build descriptor for pass/fail sections
BUILD_NUMBER="$(cat out/.version || echo '?')"
JOB_URL="https://$SEM_ORG_NAME.semaphoreci.com/jobs/$SEMAPHORE_JOB_ID"
GH_REPO_NAME="$(git remote get-url origin | awk -F: '{print $2}' | sed 's/.git//')"
BUILD_DESC="[Build job]($JOB_URL) #$BUILD_NUMBER for [commit $SHORT_HASH](https://github.com/$GH_REPO_NAME/commits/$FULL_HASH)"

# Show cache usage before updating
cache usage

# Store build number in cache
mv out/.version __build-number
cache delete build-number
cache store build-number __build-number
rm -f __build-number

# Cache object directory
cache delete "$OBJ_CACHE_KEY"
cache store "$OBJ_CACHE_KEY" out
mv out ..

# Update last commit hash
echo $FULL_HASH > __last-commit-hash
cache delete last-commit-hash
cache store last-commit-hash __last-commit-hash
rm -f __last-commit-hash

# Store Git repository in cache
pushd ..
cache delete "$GIT_CACHE_KEY"
cache store "$GIT_CACHE_KEY" "$SEMAPHORE_GIT_DIR"
popd

# Show cache usage after updating
cache usage

# Record elapsed time
TIME_AFTER="$(date +%s)"
TIME_DELTA="$((TIME_AFTER-TIME_BEFORE))"
TIME_ELAPSED="$((TIME_DELTA/60%60))m$((TIME_DELTA%60))s"
