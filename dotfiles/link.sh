#!/bin/sh
# link — symlink these dotfiles into place. An existing real file is moved
# aside to NAME.bak-DATE first. Rerunnable; already-correct links are skipped.
set -eu
cd "$(dirname "$0")"
HERE=$(pwd)
STAMP=$(date +%Y%m%d-%H%M%S)

link() {
    src="$HERE/$1"; dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "$dst.bak-$STAMP"
        echo "moved $dst -> $dst.bak-$STAMP"
    fi
    ln -s "$src" "$dst"
    echo "linked $dst"
}

link zshrc            "$HOME/.zshrc"
link zshenv           "$HOME/.zshenv"
link zprofile         "$HOME/.zprofile"
link profile          "$HOME/.profile"
link gitignore_global "$HOME/.gitignore_global"
link zed/settings.json      "$HOME/.config/zed/settings.json"
link zed/keymap.json        "$HOME/.config/zed/keymap.json"
link zed/tasks.json         "$HOME/.config/zed/tasks.json"
link zed/custom_runfile.sh  "$HOME/.config/zed/custom_runfile.sh"
link pi/models.json         "$HOME/.pi/agent/models.json"
link pi/settings.json       "$HOME/.pi/agent/settings.json"
link pi/extensions/browser.ts "$HOME/.pi/agent/extensions/browser.ts"
link claude/settings.json   "$HOME/.claude/settings.json"

# ~/.gitconfig stays a real file: it holds the per-machine identity and
# includes the shared part from here.
if ! grep -qs "dotfiles/gitconfig" "$HOME/.gitconfig"; then
    printf '[include]\n\tpath = %s/gitconfig\n' "$HERE" >> "$HOME/.gitconfig"
    echo "added include to ~/.gitconfig"
fi
if ! git config --global user.email >/dev/null; then
    echo "set your git identity: git config --global user.name NAME; git config --global user.email EMAIL" >&2
fi

# pi reads the same instructions file as Claude Code, and its curator
# extension is its own repo.
if [ ! -e "$HOME/.pi/agent/AGENTS.md" ]; then
    ln -s "$HOME/.claude/CLAUDE.md" "$HOME/.pi/agent/AGENTS.md" && echo "linked ~/.pi/agent/AGENTS.md"
fi
if [ -d "$HOME/repos/pi-curator" ] && [ ! -e "$HOME/.pi/agent/extensions/pi-curator" ]; then
    ln -s "$HOME/repos/pi-curator" "$HOME/.pi/agent/extensions/pi-curator" && echo "linked pi-curator extension"
fi
echo "done"
