#!/usr/bin/env bash
# Cài / cập nhật Evovi agent skills cho Claude Code và/hoặc Codex.
#
# Cài lần đầu (curl | bash) — xem README "Bắt đầu nhanh":
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash                 # cả hai
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash -s -- --claude  # chỉ Claude Code
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash -s -- --codex   # chỉ Codex
#   curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash -s -- --project # theo dự án
#
# Sau lần cài đầu, lệnh `evovi-skills` đã có sẵn trong PATH — cập nhật giống "npm update":
#   evovi-skills update     # kéo bản mới nhất và cài lại theo phạm vi đã chọn lần trước
#   evovi-skills            # cài lại (phạm vi đã chọn)
#   evovi-skills --claude   # đổi phạm vi rồi cài lại
set -euo pipefail

REPO_URL="https://github.com/daobinhgiang/evo-artifact.git"
SKILLS=(senior-engineer deep-exploration parallel-execution code-quality-review codebase-review codebase-wide-change codex-triage ship)

BIN_DIR="$HOME/.local/bin"
LAUNCHER="$BIN_DIR/evovi-skills"
CONFIG_DIR="$HOME/.config/evovi-skills"
SCOPE_FILE="$CONFIG_DIR/scope"

arg="${1:-}"

# `update` / `upgrade` = dùng lại phạm vi đã lưu từ lần cài trước.
if [ "$arg" = "update" ] || [ "$arg" = "upgrade" ]; then
  if [ -f "$SCOPE_FILE" ]; then
    arg="$(cat "$SCOPE_FILE")"
  else
    arg=""   # chưa lưu phạm vi -> mặc định cả hai
  fi
fi

# Resolve đích cài theo flag.
case "$arg" in
  --claude)  dests=("$HOME/.claude/skills");                                  scope="--claude" ;;
  --codex)   dests=("$HOME/.agents/skills");                                  scope="--codex" ;;
  --project) dests=("$(pwd)/.claude/skills" "$(pwd)/.agents/skills");         scope="--project" ;;
  "")        dests=("$HOME/.claude/skills" "$HOME/.agents/skills");           scope="" ;;
  *) echo "Tham số không hợp lệ: $arg"; exit 1 ;;
esac

# Nguồn skills: dùng checkout local nếu có; nếu chạy qua `curl | bash` hoặc qua lệnh
# `evovi-skills` thì tự clone bản mới nhất vào thư mục tạm.
REPO_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  maybe="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  [ -d "$maybe/skills" ] && REPO_DIR="$maybe"
fi
if [ -z "$REPO_DIR" ]; then
  command -v git >/dev/null 2>&1 || { echo "Cần có 'git' để cài/cập nhật qua mạng."; exit 1; }
  REPO_DIR="$(mktemp -d)"
  trap 'rm -rf "$REPO_DIR"' EXIT
  echo "Đang tải evo-artifact mới nhất từ GitHub..."
  git clone --depth 1 "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1
fi

for dest in "${dests[@]}"; do
  mkdir -p "$dest"
  for s in "${SKILLS[@]}"; do
    rm -rf "${dest:?}/$s"
    cp -R "$REPO_DIR/skills/$s" "$dest/$s"
    echo "đã cài $s -> $dest/$s"
  done
done

# Cài lệnh ngắn `evovi-skills` vào PATH để lần sau chỉ cần gõ `evovi-skills update`.
mkdir -p "$BIN_DIR" "$CONFIG_DIR"
cp "$REPO_DIR/scripts/install.sh" "$LAUNCHER"
chmod +x "$LAUNCHER"
printf '%s\n' "$scope" > "$SCOPE_FILE"

echo
echo "Xong. Khởi động lại agent, rồi /help (Claude Code) hoặc /skills (Codex) để kiểm tra."
echo "Lần sau cập nhật chỉ cần:  evovi-skills update"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo
    echo "Lưu ý: $BIN_DIR chưa nằm trong PATH. Thêm dòng sau vào ~/.zshrc (hoặc ~/.bashrc):"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "rồi mở lại terminal để dùng được lệnh 'evovi-skills'."
    ;;
esac
