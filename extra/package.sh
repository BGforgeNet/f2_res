#!/bin/bash

set -xeu -o pipefail

export WINEARCH="win32"
export WINEDEBUG="-all"
extra_dir="$(realpath extra)"
bin_dir="$extra_dir/bin"
dat2a="wine $bin_dir/dat2.exe a"
file_list="$(realpath file.list)"
release_dir="$(realpath release)"
mod_name=f2_res

# package filename
short_sha="$(git rev-parse --short HEAD)"
version="git$short_sha"
if [[ -n "${GITHUB_REF-}" ]]; then
    if echo "$GITHUB_REF" | grep "refs/tags"; then # tagged
        # shellcheck disable=SC2001 # sed is more readable
        version="$(echo "$GITHUB_REF" | sed 's|refs\/tags\/||')"
    fi
fi
zip="${mod_name}_${version}.zip"

rm -rf "$release_dir/text"
mv text "$release_dir/text"
rm -rf "$release_dir/text/po"

# TODO: this is a hack to match sfall default path for Traditional Chinese.
# msg2po extract to "tchinese", as that's the corresponding PO name/slug for that language.
# Need to find a more permanent solution that doesn't require manual steps.
mv "$release_dir/text/tchinese" "$release_dir/text/cht"

cd "$release_dir"

dat="${mod_name}.dat"
find . -type f | sed -e 's|^\.\/||' -e 's|\/|\\|g' | sort >"$file_list"
$dat2a "$release_dir/$dat" @"$file_list"

zip "$zip" $dat
mv "$zip" ..
