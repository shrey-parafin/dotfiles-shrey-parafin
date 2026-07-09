# dotfiles-shrey-parafin

Small company-machine dotfiles repo. This tracks Zsh, Ghostty, Atuin, and the Homebrew bundle for this machine.

## Tools

Install after reviewing `Brewfile`:

```zsh
brew bundle --file Brewfile
```

Current tool candidates:

| Tool | Why it is here |
| --- | --- |
| `PT Mono` | Font used by Ghostty config; present at `/System/Library/Fonts/Supplemental/PTMono.ttc`. |
| `fzf` | Fuzzy picker for files, history, directories, and custom scripts. |
| `fd` | Fast, friendly file finder; pairs very well with `fzf`. |
| `ripgrep` | Fast text search across repos. |
| `bat` | Syntax-highlighted file previews. |
| `eza` | Better `ls`/tree output. |
| `navi` | Interactive cheatsheet picker; wired to `Cmd+G` in Ghostty. |
| `zoxide` | Smarter `cd` based on directory usage. |
| `atuin` | Searchable shell history backed by SQLite. |
| `tealdeer` | Fast `tldr` examples for commands. |
| `lazygit` | Terminal UI for git. |
| `gh` | GitHub CLI. |
| `git-lfs` | Git large-file support; keep only if needed. |

## fd + fzf

`fd` finds paths. `fzf` lets you interactively choose one of the lines it receives.

```zsh
# Pick a file and open it in $EDITOR.
$EDITOR "$(fd --type f | fzf)"

# Pick a directory and cd into it.
cd "$(fd --type d | fzf)"

# Search file contents, then pick a matching line.
rg --line-number --no-heading "TODO" | fzf

# Preview files while picking.
fd --type f | fzf --preview 'bat --style=numbers --color=always {}'
```

How the pieces fit:

- `|` sends output from the command on the left into the command on the right.
- `$(...)` runs the command inside and replaces itself with that command's output.
- `"$(...)"` keeps the selected path as one argument, even if it contains spaces.
- `$EDITOR` expands to your editor command.
- `{}` is an `fzf` placeholder for the currently highlighted item.

## Atuin

Keep Atuin conservative on a company machine:

- `auto_sync = false` only disables network sync to an Atuin account.
- Local shell history still writes to Atuin's SQLite database.
- Atuin records commands after your shell loads `eval "$(atuin init zsh)"`.
- This repo wires Atuin like the old dotfiles: `Ctrl-X Ctrl-R` opens Atuin search, while `Ctrl-R` and up-arrow stay available for other history behavior.
- Keep `secrets_filter = true`.
- Use `store_failed = false` if failed commands add noise.
- Add `history_filter` patterns for commands that may include tokens.
- Use `atuin history prune --dry-run` before pruning old entries.
- Use `atuin history dedup --dry-run --before <date> --dupkeep 1` before deduplicating.

## Ghostty

```zsh
cd ~/Desktop/dev/dotfiles-shrey-parafin
mkdir -p ~/.config
ln -s "$PWD/.config/ghostty" ~/.config/ghostty
ls -la ~/.config/ghostty
```

Reload Ghostty config with `Cmd+Shift+,`.

## Zsh

```zsh
cd ~/Desktop/dev/dotfiles-shrey-parafin
ln -s "$PWD/.zshrc" ~/.zshrc
```

The tracked `.zshrc` sets up local binaries, Bun, Python 3.14 from Homebrew, and the repo-local Atuin integration.
