#!/usr/bin/env bash
# The shebang is solely for shellcheck auditing; this script must be sourced
# for proper functionality.

# Send an error message to Telegram
curl --form-string chat_id="$TG_CHAT_ID" -F parse_mode="Markdown" -F text="$BUILD_DESC *failed* after $TIME_ELAPSED." -F disable_web_page_preview="true" "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage"

# Send Telegram separator
curl --form-string chat_id="$TG_CHAT_ID" -F sticker="$TG_SEPARATOR_ID" -F disable_notification="true" "https://api.telegram.org/bot$TG_BOT_TOKEN/sendSticker"
