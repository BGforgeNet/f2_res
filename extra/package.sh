#!/bin/bash

set -xeu -o pipefail

EXTRA_DIR="$(realpath extra)"
BIN_DIR="$EXTRA_DIR/bin"
RELEASE_DIR="$(realpath release)"
MOD_NAME=f2_res

DAT3_VERSION="v0.11.1"
DAT3_URL="https://github.com/BGforgeNet/dat3/releases/download/${DAT3_VERSION}/dat3"
DAT3="$BIN_DIR/dat3"
# zlib level for the .dat: 6 packs in under half the time of 9, for an archive about 1% larger.
DAT3_LEVEL=6

# Download dat3 tool if it doesn't exist
if [[ ! -f "$DAT3" ]]; then
    mkdir -p "$BIN_DIR"
    wget -q "$DAT3_URL" -O "$DAT3"
    chmod +x "$DAT3"
fi

# package filename
SHORT_SHA="$(git rev-parse --short HEAD)"
VERSION="git$SHORT_SHA"
if [[ -n "${GITHUB_REF-}" ]]; then
    if echo "$GITHUB_REF" | grep "refs/tags"; then # tagged
        # shellcheck disable=SC2001 # sed is more readable
        VERSION="$(echo "$GITHUB_REF" | sed 's|refs\/tags\/||')"
    fi
fi
ZIP_FILE="${MOD_NAME}_${VERSION}.zip"

# Package from a copy, so that the working tree keeps its text/ directory.
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
stage_dir="$work_dir/files"
mkdir "$stage_dir"
cp -a "$RELEASE_DIR/." "$stage_dir/"
rm -rf "$stage_dir/text"
cp -a text "$stage_dir/text"
rm -rf "$stage_dir/text/po"

# TODO: this is a hack to match sfall default path for Traditional Chinese.
# msg2po extract to "tchinese", as that's the corresponding PO name/slug for that language.
# Need to find a more permanent solution that doesn't require manual steps.
mv "$stage_dir/text/tchinese" "$stage_dir/text/cht"

DAT_FILE="${MOD_NAME}.dat"
"$DAT3" a -c "$DAT3_LEVEL" -C "$stage_dir" "$work_dir/$DAT_FILE" '*'

# The .dat is compressed already, so the zip only stores it.
rm -f "$RELEASE_DIR/../$ZIP_FILE"
(cd "$work_dir" && zip -0 "$RELEASE_DIR/../$ZIP_FILE" "$DAT_FILE")
