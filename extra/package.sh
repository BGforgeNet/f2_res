#!/bin/bash

set -xeu -o pipefail

EXTRA_DIR="$(realpath extra)"
BIN_DIR="$EXTRA_DIR/bin"
RELEASE_DIR="$(realpath release)"
MOD_NAME=f2_res

# Download dat3 tool if it doesn't exist
DAT3_VERSION="v0.6.0"
DAT3_URL="https://github.com/BGforgeNet/dat3/releases/download/${DAT3_VERSION}/dat3"
DAT3="$BIN_DIR/dat3"
if [[ ! -f "$DAT3" ]]; then
	mkdir -p "$BIN_DIR"
    wget -q "$DAT3_URL" -O "$DAT3"
    chmod +x "$DAT3"
fi

# package filename
short_sha="$(git rev-parse --short HEAD)"
version="git$short_sha"
if [[ -n "${GITHUB_REF-}" ]]; then
    if echo "$GITHUB_REF" | grep "refs/tags"; then # tagged
        # shellcheck disable=SC2001 # sed is more readable
        version="$(echo "$GITHUB_REF" | sed 's|refs\/tags\/||')"
    fi
fi
ZIP_FILE="${MOD_NAME}_${version}.zip"

rm -rf "$RELEASE_DIR/text"
mv text "$RELEASE_DIR/text"
rm -rf "$RELEASE_DIR/text/po"

# TODO: this is a hack to match sfall default path for Traditional Chinese.
# msg2po extract to "tchinese", as that's the corresponding PO name/slug for that language.
# Need to find a more permanent solution that doesn't require manual steps.
mv "$RELEASE_DIR/text/tchinese" "$RELEASE_DIR/text/cht"

cd "$RELEASE_DIR"

DAT_FILE="${MOD_NAME}.dat"
"$DAT3" a "$DAT_FILE" \*

zip "$ZIP_FILE" $DAT_FILE
mv "$ZIP_FILE" ..
