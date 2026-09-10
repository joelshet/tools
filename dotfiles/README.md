# dotfiles

Shell, git, Zed, pi, and Claude Code settings, symlinked into place by `link.sh`. Edit the files here; the links mean the live config and the repo are the same file.

```
zshrc zshenv zprofile profile   -> ~/.zshrc etc.
gitignore_global                -> ~/.gitignore_global
gitconfig                       included from ~/.gitconfig (see below)
zed/                            -> ~/.config/zed/{settings,keymap,tasks}.json, custom_runfile.sh
pi/                             -> ~/.pi/agent/{models,settings}.json, extensions/browser.ts
claude/settings.json            -> ~/.claude/settings.json
```

## Setting up a new laptop

1. Clone the repo and put it at `~/tools` (see the root README), then run:

   ```sh
   ~/tools/dotfiles/link.sh
   ```

   An existing real file at any target is moved to `NAME.bak-DATE` before the link is made. Rerunning is safe.

2. Set the machine's git identity. `gitconfig` here holds only the shared parts (excludes file, diff and merge tools); `~/.gitconfig` stays a real file with `[user]` plus an `[include]` that `link.sh` appends.

   ```sh
   git config --global user.name "Joel"
   git config --global user.email "you@example.com"
   ```

3. Copy by hand what is personal and not in this public repo: `~/.claude/CLAUDE.md` (global instructions, which pi also reads through `~/.pi/agent/AGENTS.md`), `~/.claude/projects/*/memory/`, and `~/.pi/agent/auth.json`.

4. Install what the shell files expect, or delete the lines: Homebrew (`brew bundle` with the `Brewfile` in the repo root), rustup (`~/.cargo/env`), uv (`~/.local/bin/env`), nvm via Homebrew, zoxide, LM Studio.

## What is deliberately left out

- `~/.claude/CLAUDE.md` and memory files: personal, not for a public repo.
- `~/.pi/agent/auth.json`, `models-store.json`, `sessions/`: credentials and state.
- Zed `conversations/`, `prompts/`, `themes/`, `settings_backup.json`: state and leftovers.
- `~/.zsh_history` and friends.

## Removal

`rm` each symlink listed at the top, drop the `[include]` block from `~/.gitconfig`, and restore any `.bak-DATE` file you want back.
