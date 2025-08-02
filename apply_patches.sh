#!/bin/bash

set -e

patches="$(readlink -f -- "$1")"
build_root="$(readlink -f "$patches/../..")"  # <- zwei Ebenen hoch zu LeOS_Mai

for patchdir in "$patches"/*; do
    project="$(basename "$patchdir")"

    p="$(echo "$project" | sed -e 's;platform_;;g' | tr _ /)"
    [ "$p" == "build" ] && p="build/make"
    [ "$p" == "treble/adapter" ] && p="treble_adapter"
    [ "$p" == "vendor/hardware/overlay" ] && p="vendor/hardware_overlay"

    target="$build_root/$p"
    if [ ! -d "$target" ]; then
        echo "⚠️  Zielverzeichnis $target existiert nicht, überspringe..."
        continue
    fi

    echo "➡️  Wechsle in $target"
    pushd "$target" >/dev/null

    for patch in "$patchdir"/*.patch; do
        [ -f "$patch" ] || continue
        echo "📦  Wende Patch $patch an"
        git am "$patch" || exit 1
    done

    popd >/dev/null
done

echo "✅  Alle Patches angewendet."

cd device/phh/treble/
bash generate.sh
cd ../../..

echo "✅  generate.sh gestartet"

