#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/scripts/paths.sh"
if (( $# < 1 )); then
    ask_path export_folder 'web export folder' "$root/build/web"
else
    export_folder="$1"
fi
if (( $# < 2 )); then
    ask_path output_folder 'output folder' "$root/docs"
else
    output_folder="$2"
fi
if [[ ! -d "$export_folder" || -z "$output_folder" ]]; then
    echo 'choose an export folder and output folder' >&2
    exit 1
fi
source="$(realpath "$export_folder")"
output="$(realpath -m "$output_folder")"
part_size=20000000

if [[ "$output" == "$source" || "$output" == "$source/"* || "$source" == "$output/"* ]]; then
    echo 'use separate input and output folders' >&2
    exit 1
fi
if [[ -e "$output" ]]; then
    echo "output exists: $output" >&2
    exit 1
fi
for file in index.pck index.html; do
    if [[ ! -s "$source/$file" ]]; then
        echo "missing export: $source/$file" >&2
        exit 1
    fi
done
if ! grep -Eq "src=['\"]index\.js['\"]" "$source/index.html" ||
   ! grep -Eq '(const|var|let) engine = new Engine\(' "$source/index.html"; then
    echo 'use the default godot html page' >&2
    exit 1
fi

mkdir -p "$output"
trap 'rm -rf -- "$output"' ERR
cp -a "$source/." "$output/"
rm -- "$output/index.pck"
split -b "$part_size" -d -a 4 "$source/index.pck" "$output/index.pck.part-"

manifest="$output/index.pck.json"
printf '{\n  "size": %s,\n  "parts": [\n' "$(stat -c %s "$source/index.pck")" > "$manifest"
separator=''
for part in "$output/"index.pck.part-*; do
    hash="$(sha256sum "$part")"
    printf '%s    {"file": "%s", "size": %s, "sha256": "%s"}' \
        "$separator" "$(basename "$part")" "$(stat -c %s "$part")" "${hash%% *}" >> "$manifest"
    separator=$',\n'
done
printf '\n  ]\n}\n' >> "$manifest"

cp "$root/scripts/pck-loader.js" "$output/pck-loader.js"
touch "$output/.nojekyll"
sed -i '/src=.*index\.js.*<\/script>/a\        <script src="pck-loader.js"></script>' "$output/index.html"
sed -i '/engine = new Engine(/a\loadSplitPck(engine);' "$output/index.html"
trap - ERR
echo "split export saved to $output"
