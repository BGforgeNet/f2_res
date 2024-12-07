#!/bin/bash

set -xeu -o pipefail

export WINEARCH="win32"
export WINEDEBUG="-all"
extra_dir="$(realpath extra)"
bin_dir="$extra_dir/bin"
dat2a="wine $bin_dir/dat2.exe a -1"
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
cd "$release_dir"

dat="${mod_name}.dat"
find . -type f | sed -e 's|^\.\/||' -e 's|\/|\\|g' | sort >"$file_list"
$dat2a "$release_dir/$dat" @"$file_list"

zip "$zip" $dat
mv "$zip" ..
