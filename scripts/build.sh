#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
project="$root/work/project"
source "$root/scripts/paths.sh"

if [[ ! -f "$project/project.godot" ]]; then
    echo 'missing work/project; run scripts/recover.sh first' >&2
    exit 1
fi

ask_path godot 'godot executable' "$(command -v godot || true)"
if ! command -v "$godot" >/dev/null 2>&1; then
    echo 'godot executable not found' >&2
    exit 1
fi

case "$("$godot" --version)" in
    3.6.*)
        export_args=(--export)
        errors='^SCRIPT ERROR:'
        ;;
    4.[3-9].*|4.[1-9][0-9].*)
        export_args=(--headless --rendering-method gl_compatibility --export-release)
        errors='^SCRIPT ERROR:|^ERROR:'
        ;;
    *)
        echo 'use godot 3.6.x or 4.3+ with web export templates' >&2
        exit 1
        ;;
esac

for preset in web web-threads; do
    output="$root/build/$preset"
    log="$root/work/$preset.log"
    rm -rf -- "$output"
    mkdir -p "$output"

    "$godot" --path "$project" "${export_args[@]}" "$preset" "$output/index.html" 2>&1 | tee "$log"

    # Godot sometimes reports leaked resources while closing the headless editor.
    if grep -E "$errors" "$log" | grep -vE '^ERROR: ([0-9]+ (resources still in use|RID allocations)|Pages in use exist)'; then
        echo "export failed; see $log" >&2
        exit 1
    fi

    for file in index.html index.pck index.wasm; do
        if [[ ! -s "$output/$file" ]]; then
            echo "missing export: $output/$file" >&2
            exit 1
        fi
    done
    echo "exported $output"
done
