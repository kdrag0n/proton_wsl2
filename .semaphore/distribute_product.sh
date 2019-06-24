#!/usr/bin/env bash
# The shebang is solely for shellcheck auditing; this script must be sourced
# for proper functionality.

# Generate and update product file name
PRODUCT="ProtonKernel-wsl2-ci-$BUILD_NUMBER-$SHORT_HASH.bin"
cp ../out/arch/x86/boot/compressed/vmlinux.bin "$PRODUCT"

# Generate changelog based on Git commits
CHANGELOG="$(echo -e "$BUILD_DESC *succeeded* after $TIME_ELAPSED.\n\n*Changes since last build:*"; git log --pretty=format:"​ ​ ​ ​ • %s" --committer=kdrag0n $LAST_COMMIT..HEAD)"

# Upload the product and changelog to Telegram
curl --form-string chat_id="$TG_CHAT_ID" -F document=@"$PRODUCT" "https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument"
curl --form-string chat_id="$TG_CHAT_ID" -F parse_mode="Markdown" -F text="$CHANGELOG" -F disable_web_page_preview="true" -F disable_notification="true" "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage"

# Send Telegram separator
curl --form-string chat_id="$TG_CHAT_ID" -F sticker="$TG_SEPARATOR_ID" -F disable_notification="true" "https://api.telegram.org/bot$TG_BOT_TOKEN/sendSticker"

# Upload the product to transfer.sh
# Enforce a 1m30s timeout because transfer.sh sometimes hangs
timeout 1.5m curl --progress-bar -T "$PRODUCT" "https://transfer.sh/$PRODUCT"
