#!/usr/bin/env bash
# Cài Evovi agent skills cho Claude Code và/hoặc Codex.
#   ./scripts/install.sh            # cả hai: ~/.claude/skills + ~/.agents/skills
#   ./scripts/install.sh --claude   # chỉ Claude Code (~/.claude/skills)
#   ./scripts/install.sh --codex    # chỉ Codex      (~/.agents/skills)
#   ./scripts/install.sh --project  # theo dự án:    ./.claude/skills + ./.agents/skills
#   ./scripts/install.sh --playwright      # thêm Playwright MCP server (isolated) cho skill /test (mặc định 5)
#   ./scripts/install.sh --playwright=7    # thêm đúng 7 server (playwright..playwright7)
# (Có thể kết hợp, ví dụ: ./scripts/install.sh --claude --playwright=5)
#
# Cài nhanh không cần clone (curl | bash) — xem README "Bắt đầu nhanh":
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash -s -- --claude
set -euo pipefail

REPO_URL="https://github.com/daobinhgiang/evo-artifact.git"
SKILLS=(senior-engineer deep-exploration parallel-execution code-quality-review codebase-review codebase-wide-change codex-triage ship test)

# Thiết lập N Playwright MCP server isolated cho skill /test (mỗi server = 1 trình duyệt chạy song song).
# Dùng 'claude' CLI ở scope user (toàn cục). Tham khảo skills/test/references/mcp-setup.md.
setup_playwright_mcp() {
  local count="$1" i name added=0
  if ! command -v claude >/dev/null 2>&1; then
    echo "Bỏ qua Playwright MCP: không tìm thấy 'claude' CLI."
    echo "  Cài Claude Code rồi chạy lại với --playwright, hoặc thêm thủ công theo skills/test/references/mcp-setup.md."
    return 0
  fi
  echo "Thiết lập $count Playwright MCP server (isolated) cho /test..."
  for i in $(seq 1 "$count"); do
    [ "$i" -eq 1 ] && name="playwright" || name="playwright$i"
    if claude mcp get "$name" >/dev/null 2>&1; then
      echo "  $name đã tồn tại — bỏ qua"
    elif claude mcp add --scope user "$name" -- npx @playwright/mcp@latest --isolated >/dev/null 2>&1; then
      echo "  đã thêm $name"; added=$((added+1))
    else
      echo "  KHÔNG thêm được $name — thêm thủ công theo skills/test/references/mcp-setup.md"
    fi
  done
  echo "  Xong Playwright MCP ($added server mới). Cần --isolated để mỗi server có profile riêng, không tranh khóa."
  echo "  -> Khởi động lại Claude Code để kết nối server mới (duyệt nếu được hỏi)."
}

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

# Phân tích tham số: tách chế độ đích (--claude/--codex/--project) khỏi --playwright[=N].
mode=""
pw_setup=false
pw_count=5
for arg in "$@"; do
  case "$arg" in
    --claude|--codex|--project) mode="$arg" ;;
    --playwright)   pw_setup=true ;;
    --playwright=*) pw_setup=true; pw_count="${arg#*=}" ;;
    *) echo "Tham số không hợp lệ: $arg"; exit 1 ;;
  esac
done

case "$mode" in
  --claude)  dests=("$HOME/.claude/skills") ;;
  --codex)   dests=("$HOME/.agents/skills") ;;
  --project) dests=("$(pwd)/.claude/skills" "$(pwd)/.agents/skills") ;;
  "")        dests=("$HOME/.claude/skills" "$HOME/.agents/skills") ;;
esac

for dest in "${dests[@]}"; do
  mkdir -p "$dest"
  for s in "${SKILLS[@]}"; do
    rm -rf "${dest:?}/$s"
    cp -R "$REPO_DIR/skills/$s" "$dest/$s"
    echo "đã cài $s -> $dest/$s"
  done
done

# Playwright MCP cho skill /test: thiết lập nếu được yêu cầu, nếu không thì gợi ý.
if [ "$pw_setup" = true ]; then
  setup_playwright_mcp "$pw_count"
else
  echo "Mẹo: skill /test cần nhiều Playwright MCP server song song. Chạy lại với --playwright (hoặc --playwright=N) để tự thêm."
fi

echo "Xong. Khởi động lại agent, rồi /help (Claude Code) hoặc /skills (Codex) để kiểm tra."
