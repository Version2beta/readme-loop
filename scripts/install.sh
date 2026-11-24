#!/usr/bin/env bash
# Install a self-contained copy; never replace an existing skill.
set -euo pipefail
usage='Usage: bash scripts/install.sh --claude|--pi|--codex'
if [ "${1:-}" = --help ] && [ "$#" = 1 ]; then
  echo "$usage"
  echo 'Copies into the selected user skill directory; refuses existing paths.'
  exit 0
fi
if [ "$#" != 1 ]; then
  echo "$usage" >&2
  exit 2
fi
case "$1" in
  --claude) skill_path=.claude/skills; invocation=/readme-loop ;;
  --pi) skill_path=.pi/agent/skills; invocation=/skill:readme-loop ;;
  --codex) skill_path=.agents/skills; invocation='$readme-loop' ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
: "${HOME:?HOME must be set}"
source_dir=$(cd "$(dirname "$0")/.." && pwd)
parent="$HOME/$skill_path"
dest="$parent/readme-loop"
# Preflight before creating the destination.
for entry in SKILL.md README.md references scripts tests; do
  [ -e "$source_dir/$entry" ] || { echo "Missing package file: $entry" >&2; exit 1; }
done
mkdir -p "$parent"
if ! mkdir "$dest" 2>/dev/null; then
  echo "Cannot create $dest; an existing installation will not be overwritten." >&2
  exit 1
fi
# mkdir above claims a new directory atomically, including against symlinks.
if ! cp -R "$source_dir/SKILL.md" "$source_dir/README.md" \
  "$source_dir/references" "$source_dir/scripts" "$source_dir/tests" "$dest/"; then
  echo "Copy failed; incomplete installation remains at $dest. Inspect it before retrying." >&2
  exit 1
fi
printf 'Installed: %s\nStart a fresh agent session in your project, then use %s.\n' "$dest" "$invocation"
echo 'No model calls, settings changes, or implementation loop were run.'
