#!/usr/bin/env bash
# Cài Evovi agent skills cho Claude Code và/hoặc Codex.
#   ./scripts/install.sh            # cả hai: ~/.claude/skills + ~/.agents/skills
#   ./scripts/install.sh --claude   # chỉ Claude Code (~/.claude/skills)
#   ./scripts/install.sh --codex    # chỉ Codex      (~/.agents/skills)
#   ./scripts/install.sh --project  # theo dự án:    ./.claude/skills + ./.agents/skills
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS=(senior-engineer ship)

case "${1:-}" in
  --claude)  dests=("$HOME/.claude/skills") ;;
  --codex)   dests=("$HOME/.agents/skills") ;;
  --project) dests=("$(pwd)/.claude/skills" "$(pwd)/.agents/skills") ;;
  "")        dests=("$HOME/.claude/skills" "$HOME/.agents/skills") ;;
  *) echo "Tham số không hợp lệ: $1"; exit 1 ;;
esac

for dest in "${dests[@]}"; do
  mkdir -p "$dest"
  for s in "${SKILLS[@]}"; do
    rm -rf "${dest:?}/$s"
    cp -R "$REPO_DIR/skills/$s" "$dest/$s"
    echo "đã cài $s -> $dest/$s"
  done
done

echo "Xong. Khởi động lại agent, rồi /help (Claude Code) hoặc /skills (Codex) để kiểm tra."
