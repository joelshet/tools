#!/bin/sh
# install — link ~/tabs and ~/routines to this folder, build TabGroups.app,
# and launch it. Safe to rerun after editing TabGroups.swift.
set -eu
cd "$(dirname "$0")"
HERE=$(pwd)

link() {
    target=$1; path=$2
    if [ -L "$path" ]; then
        [ "$(readlink "$path")" = "$target" ] && return
        echo "$path already links to $(readlink "$path"); remove it and rerun" >&2
        exit 1
    fi
    if [ -e "$path" ]; then
        echo "$path exists and is not a symlink. Move its files into $target, delete it, and rerun." >&2
        exit 1
    fi
    ln -s "$target" "$path"
    echo "linked $path -> $target"
}

link "$HERE/tabs" "$HOME/tabs"
link "$HERE/routines" "$HOME/routines"

if [ ! -x "$HOME/tools/tabs" ]; then
    echo "~/tools/tabs not found. Point ~/tools at this repo first: ln -s $(dirname "$HERE") ~/tools" >&2
    exit 1
fi

./build.sh

pkill -x TabGroups 2>/dev/null || true
i=0
while pgrep -xq TabGroups; do
    i=$((i + 1)); [ "$i" -lt 50 ] || { echo "old TabGroups did not quit" >&2; exit 1; }
    sleep 0.1
done
open "$HERE/TabGroups.app"
echo "TabGroups.app running from $HERE (registers itself as a login item)"
