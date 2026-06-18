#!/usr/bin/env bash
# Install the Evovi skills into Claude Code.
#   ./scripts/install.sh             # global  -> ~/.claude/skills
#   ./scripts/install.sh --project   # project -> ./.claude/skills
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS=(senior-engineer ship)

if [[ "${1:-}" == "--project" ]]; then
  DEST="$(pwd)/.claude/skills"
else
  DEST="$HOME/.claude/skills"
fi

mkdir -p "$DEST"
for s in "${SKILLS[@]}"; do
  rm -rf "${DEST:?}/$s"
  cp -R "$REPO_DIR/skills/$s" "$DEST/$s"
  echo "installed $s -> $DEST/$s"
done

echo "Done. Restart Claude Code and run /help to confirm."
