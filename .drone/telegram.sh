#!/usr/bin/env bash
# Drone CI kernel pipeline - Telegram integration script

# Exit if skip marker is present
[[ -f "$DRONE_WORKSPACE/skip_exec" ]] && exit

# Helper function to send a Telegram message
function tg_send() {
    local msg_type="$1"
    shift

    local args=()
    for arg in "$@"; do
        args+=(-F "$arg")
    done

    curl -sf --form-string chat_id="$TG_CHAT_ID" "${args[@]}" "https://api.telegram.org/bot$TG_BOT_TOKEN/send$msg_type" > /dev/null
}

# Log all commands executed and exit on error
set -ve

# Generate build descriptor
SHORT_HASH=$(cut -c-8 <<< $DRONE_COMMIT)
BUILD_LINK="https://cloud.drone.io/$DRONE_REPO_NAMESPACE/$DRONE_REPO_NAME/$DRONE_BUILD_NUMBER"
BUILD_DESC="[Build job]($BUILD_LINK) $DRONE_BUILD_NUMBER for [commit $SHORT_HASH]($DRONE_REPO_LINK/commits/$DRONE_COMMIT) on branch \`$DRONE_BRANCH\`"

# Get elapsed time
TIME_AFTER="$(date +%s)"
TIME_DELTA="$((TIME_AFTER-DRONE_BUILD_STARTED))"
TIME_ELAPSED="$((TIME_DELTA/60%60))m$((TIME_DELTA%60))s"

# On success
if [[ "$DRONE_JOB_STATUS" == "success" ]]; then
    # Enter the cloned repo
    cd "$DRONE_REPO_NAME"

    # Read product name from disk
    PRODUCT_NAME="$(cat out/product_name.txt)"

    # Send separator sticker
    tg_send Sticker sticker="$TG_SEPARATOR_ID" disable_notification=true

    # Upload product
    tg_send Document document=@"$PRODUCT_NAME" parse_mode=Markdown caption="$BUILD_DESC *succeeded* after $TIME_ELAPSED."

    # Generate changelog message
    CHANGELOG="Changes since last build:
$(cat "$DRONE_WORKSPACE/changelog.txt")"

    # Truncate changelog for Telegram's 4096-character limit, if necessary
    if [[ "$(wc -c <<< "$CHANGELOG")" -gt 4096 ]]; then
        # Upload full changelog to del.dog
        json_res="$(curl -sf --data-binary "$CHANGELOG" https://del.dog/documents)"
        doc_key="$(jq -r .key <<< "$json_res")"
        paste_url="https://del.dog/$doc_key"

        # Generate Telegram footer
        footer="...
**Truncated** — [full changelog here]($paste_url)."
        footer_len="$(wc -c <<< "$footer")"

        # Truncate Telegram changelog and append footer
        CHANGELOG="$(cut -c-$((4096-$footer_len)) <<< "$CHANGELOG")$footer"
    fi

    tg_send Message text="$CHANGELOG" disable_web_page_preview=true disable_notification=true

# On failure
elif [[ "$DRONE_JOB_STATUS" == "failure" ]]; then
    # Send separator sticker
    tg_send Sticker sticker="$TG_SEPARATOR_ID" disable_notification=true

    # Send error message
    tg_send Message parse_mode=Markdown text="$BUILD_DESC *failed* after $TIME_ELAPSED." disable_web_page_preview=true

# On unknown status
else
    echo "Unknown job status '$DRONE_JOB_STATUS'; bailing."

    # Send separator sticker
    tg_send Sticker sticker="$TG_SEPARATOR_ID" disable_notification=true

    # Send error message
    tg_send Message parse_mode=Markdown text="$BUILD_DESC finished with *unknown status* `$DRONE_JOB_STATUS` after $TIME_ELAPSED." disable_web_page_preview=true

    exit 1
fi
