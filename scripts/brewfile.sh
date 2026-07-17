#!/bin/zsh
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/brewfile.sh [check|install] [common|data-platform|infrastructure|all]

Checks or installs the shared Brewfile and an optional Parafin role profile.
Defaults to: check all
USAGE
}

action="${1:-check}"
profile="${2:-all}"
script_dir="${0:A:h}"
repo_root="${script_dir:h}"

case "$action" in
  check|install) ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

case "$profile" in
  common)
    brewfiles=("${repo_root}/Brewfile")
    ;;
  data-platform)
    brewfiles=("${repo_root}/Brewfile" "${repo_root}/brewfiles/data-platform.Brewfile")
    ;;
  infrastructure)
    brewfiles=("${repo_root}/Brewfile" "${repo_root}/brewfiles/infrastructure.Brewfile")
    ;;
  all)
    brewfiles=(
      "${repo_root}/Brewfile"
      "${repo_root}/brewfiles/data-platform.Brewfile"
      "${repo_root}/brewfiles/infrastructure.Brewfile"
    )
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

for brewfile in "${brewfiles[@]}"; do
  print -r -- "${action}: ${brewfile#$repo_root/}"
  if [[ "$action" == "check" ]]; then
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_BUNDLE_NO_UPGRADE=1 \
      brew bundle check --file="$brewfile"
  else
    brew bundle install --file="$brewfile"
  fi
done
