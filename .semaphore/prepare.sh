#!/usr/bin/env bash
# The shebang is solely for shellcheck auditing; this script must be sourced
# for proper functionality.

# Enforce a time limit on the entire job to prevent credit exhaustion
(sleep $JOB_TIMEOUT && pkill -9 bash) &

# Record start time
TIME_BEFORE="$(date +%s)"

# Restore and update source code from cache, or clone if not present
GIT_CACHE_KEY="git-$SEMAPHORE_GIT_DIR"
cache restore "$GIT_CACHE_KEY"
[ ! -d "$SEMAPHORE_GIT_DIR" ] && git clone "$SEMAPHORE_GIT_URL" "$SEMAPHORE_GIT_DIR" || true
cd "$SEMAPHORE_GIT_DIR"
git fetch origin
git checkout $SEMAPHORE_GIT_BRANCH
git add .
git reset --hard $SEMAPHORE_GIT_SHA

# Restore object directory, build number, and last commit hash from cache
OBJ_CACHE_KEY="objects-$SEMAPHORE_GIT_BRANCH"
cache restore "$OBJ_CACHE_KEY"
cache restore build-number
cache restore last-commit-hash

# Skip build if no code changes were made
# This could happen if a commit message was amended and force-pushed,
# or if only meta and/or informational files were updated
LAST_COMMIT="$(cat __last-commit-hash || echo HEAD~)"
[ -z "$(git diff --raw $LAST_COMMIT..HEAD | grep -vie Documentation -e README -e COPYING -e CREDITS -e MAINTAINERS -e samples)" ] && exit || true

# Create placeholders for cached objects if necessary
mkdir -p out
touch __build-number

# Move build number from its cache location to the object directory
# This is separated from out/ in cache to make clean builds easier
mv __build-number out/.version

# Store short and full commit hashes for later use
FULL_HASH="$(git rev-parse HEAD)"
SHORT_HASH="$(git rev-parse --short=8 HEAD)"
