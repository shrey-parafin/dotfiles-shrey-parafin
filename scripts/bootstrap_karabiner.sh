#!/bin/zsh
set -euo pipefail

# Copy instead of linking: this repository lives under macOS-protected Desktop.
script_dir="${0:A:h}"
repo_root="${script_dir:h}"
source_file="${repo_root}/.config/karabiner/karabiner.json"
target_dir="${HOME}/.config/karabiner"
target_file="${target_dir}/karabiner.json"
mode="${1:---check}"

if (( $# > 1 )); then
  print -u2 'Usage: bootstrap_karabiner.sh [--check|--replace|--export]'
  exit 2
fi
case "$mode" in
  --check|--replace|--export) ;;
  *) print -u2 'Usage: bootstrap_karabiner.sh [--check|--replace|--export]'; exit 2 ;;
esac

if [[ "$mode" == --export ]]; then
  source_file="$target_file"
  target_file="${repo_root}/.config/karabiner/karabiner.json"
  target_dir="${target_file:h}"
fi

# Reject malformed data before making backups or changing the destination.
/usr/bin/ruby -rjson -e 'c=JSON.parse(File.read(ARGV[0])); abort "Missing profiles" unless c["profiles"].is_a?(Array) && !c["profiles"].empty?' "$source_file"
if [[ -L "$target_dir" || -L "$target_file" ]]; then
  print -u2 "Refusing to overwrite a symbolic link: $target_file"
  exit 1
fi
if [[ -e "$target_file" && ! -f "$target_file" ]]; then
  print -u2 "Refusing non-file destination: $target_file"
  exit 1
fi
if [[ -f "$target_file" ]] && cmp -s "$source_file" "$target_file"; then
  print -r -- "Already in sync: $target_file"
  exit 0
fi
if [[ "$mode" == --check ]]; then
  print -r -- "Would copy: $source_file -> $target_file"
  print 'Run --replace to back up and install, or --export to save live changes to the repository.'
  exit 0
fi
mkdir -p "$target_dir"
if [[ -e "$target_file" ]]; then
  backup_file="$(mktemp "${target_file}.backup.XXXXXXXX")"
  cp -p "$target_file" "$backup_file"
  print -r -- "Backup: $backup_file"
fi
temporary_file="$(mktemp "${target_dir}/.karabiner.XXXXXXXX")"
trap 'rm -f "$temporary_file"' EXIT
cp "$source_file" "$temporary_file"
chmod 600 "$temporary_file"
mv "$temporary_file" "$target_file"
print -r -- "Saved: $target_file"
