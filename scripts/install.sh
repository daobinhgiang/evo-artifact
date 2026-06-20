#!/usr/bin/env bash
# Cài Evovi agent skills cho Claude Code và/hoặc Codex.
#   ./scripts/install.sh            # cả hai: ~/.claude/skills + ~/.agents/skills
#   ./scripts/install.sh --claude   # chỉ Claude Code (~/.claude/skills)
#   ./scripts/install.sh --codex    # chỉ Codex      (~/.agents/skills)
#   ./scripts/install.sh --project  # theo dự án:    ./.claude/skills + ./.agents/skills
#
# Cài nhanh không cần clone (curl | bash) — xem README "Bắt đầu nhanh":
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash -s -- --claude
set -euo pipefail

REPO_URL="https://github.com/daobinhgiang/evo-artifact.git"
SKILLS=(senior-engineer deep-exploration parallel-execution code-quality-review codebase-review codebase-wide-change codex-triage ship)

# Nguồn skills: dùng checkout local nếu có; nếu chạy qua `curl | bash` thì tự clone vào thư mục tạm.
REPO_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  maybe="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  [ -d "$maybe/skills" ] && REPO_DIR="$maybe"
fi
if [ -z "$REPO_DIR" ]; then
  command -v git >/dev/null 2>&1 || { echo "Cần có 'git' để cài qua mạng."; exit 1; }
  REPO_DIR="$(mktemp -d)"
  trap 'rm -rf "$REPO_DIR"' EXIT
  echo "Đang tải evo-artifact từ GitHub..."
  git clone --depth 1 "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1
fi

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
