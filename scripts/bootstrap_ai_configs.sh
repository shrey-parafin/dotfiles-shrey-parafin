#!/bin/zsh
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/bootstrap_ai_configs.sh [--check] [--replace]

Links the portable Codex and Claude configuration files from this repository.
Runtime state, authentication, caches, sessions, and remote-managed settings
remain local and are not tracked.

Options:
  --check     Report what would change without writing files.
  --replace   Back up existing files before replacing them with links.
USAGE
}

check_only=0
replace=0

for arg in "$@"; do
  case "$arg" in
    --check) check_only=1 ;;
    --replace) replace=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
config_files=(
  ".codex/AGENTS.md"
  ".codex/config.toml"
  ".codex/keybindings.json"
  ".codex/rules/default.rules"
  ".claude/settings.json"
)

for relative_path in "${config_files[@]}"; do
  source_path="${repo_root}/${relative_path}"
  target_path="${HOME}/${relative_path}"

  if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
    print -r -- "ok: $target_path -> $source_path"
    continue
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    if (( ! replace )); then
      print -r -- "refusing: $target_path exists; rerun with --replace"
      exit 1
    fi

    backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S)"
    print -r -- "backup: $target_path -> $backup_path"
    if (( ! check_only )); then
      mv "$target_path" "$backup_path"
    fi
  fi

  print -r -- "create: $target_path -> $source_path"
  if (( ! check_only )); then
    mkdir -p "${target_path:h}"
    ln -s "$source_path" "$target_path"
  fi
done
