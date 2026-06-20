# Hướng dẫn sử dụng Evovi Agent Skills

Cài đặt và sử dụng các agent skill trong repo này: **họ `senior-engineer`** (gồm `senior-engineer`
và 6 skill chuyên biệt nó định tuyến tới) và **`ship`**. Tương thích với
[Claude Code](https://claude.com/claude-code) và [Codex](https://developers.openai.com/codex)
(cùng chuẩn `SKILL.md`). Chỉ dùng nội bộ Evovi — xem [README](../README.md).

| Skill | Chức năng |
|---|---|
| **`senior-engineer`** | Persona kỹ sư cấp cao + bộ định tuyến. Định hình cách agent tư duy về kỹ thuật, cân nhắc khả năng mở rộng trong mọi quyết định backend/DB/schema, và định tuyến tới các skill chuyên biệt (review code, audit, refactor toàn app, khám phá sâu, plan→build). |
| **Họ skill chuyên biệt** | `deep-exploration`, `parallel-execution`, `code-quality-review`, `codebase-review`, `codebase-wide-change`, `codex-triage` — các workflow mà `senior-engineer` định tuyến tới. Đi kèm và được cài cùng nhau. |
| **`ship`** | Pipeline một lệnh: branch → commit → push → PR, kèm tùy chọn merge + deploy. Đọc `AGENTS.md` của từng repo, cắt nhánh mới từ `develop`/`staging`, không động vào `main`. |

## Cài đặt

Dùng script (cài cho Claude Code và/hoặc Codex):

```bash
git clone https://github.com/daobinhgiang/evo-artifact.git && cd evo-artifact
./scripts/install.sh             # cả hai: ~/.claude/skills + ~/.agents/skills
./scripts/install.sh --claude    # chỉ Claude Code
./scripts/install.sh --codex     # chỉ Codex
./scripts/install.sh --project   # theo dự án
```

Hoặc copy thủ công — cả hai agent đều đọc chuẩn `SKILL.md`, chỉ khác đường dẫn:

```bash
cp -R skills/* ~/.claude/skills/   # Claude Code (cả họ senior-engineer + ship)
cp -R skills/* ~/.agents/skills/   # Codex
```

Kiểm tra: khởi động lại agent, rồi `/help` (Claude Code) hoặc `/skills` (Codex) để xác nhận
cả hai skill được liệt kê.

### Tích hợp vào Codex

Codex dùng cùng định dạng skill dạng thư mục `SKILL.md`, đặt tại `~/.agents/skills/` (toàn cục)
hoặc `.agents/skills/` (theo dự án). Sau khi cài, gọi skill bằng `/skills` hoặc nhắc tên skill.
Codex cũng tự đọc `AGENTS.md`, nên quy ước ship hoạt động ngay.

Nếu bạn đang chuyển từ Claude Code sang Codex, có thể dùng công cụ migration sẵn có của Codex:

```bash
codex --skill migrate-to-codex -- --scan-only   # quét cấu hình/skill Claude Code
codex --skill migrate-to-codex -- --plan        # xem kế hoạch import
```

## `senior-engineer`

Hoạt động ngầm — sau khi cài, nó định hình công việc kỹ thuật; bạn hiếm khi gọi tên trực tiếp.
Kích hoạt khi: cần ý kiến kỹ thuật ("act as a senior engineer"), lập kế hoạch cho một
feature/thay đổi, và bất kỳ câu hỏi nào về backend/DB/schema (nó trả lời theo các bậc khả năng
mở rộng và đề xuất bậc phù hợp).

Nó khám phá codebase trước khi trả lời, phản biện những thiết kế không mở rộng được, chấp nhận
quyết định cuối của bạn, và kết thúc bằng các bước tiếp theo cụ thể. Nó định tuyến công việc lớn
tới các skill chuyên biệt:

| Bạn muốn… | Định tuyến tới |
|---|---|
| Review một diff/PR/file cụ thể | `code-quality-review` |
| Audit toàn bộ codebase | `codebase-review` |
| Thay đổi điều gì đó trên toàn app | `codebase-wide-change` |
| Build một kế hoạch đã duyệt | `parallel-execution` |
| Hiểu code trước khi hành động | `deep-exploration` |
| Phân loại comment review của Codex | `codex-triage` |

> Sáu skill được định tuyến tới **đi kèm trong repo này** và được `install.sh` cài cùng
> `senior-engineer`. Vì `senior-engineer` là bộ định tuyến (nó gọi `Skill(...)` tới các skill
> kia), thiếu chúng thì các lệnh định tuyến sẽ lỗi — nên hãy luôn cài cả họ cùng nhau.

### (Tùy chọn) Tự động hóa plan mode bằng hook — *chỉ Claude Code*

`senior-engineer` có một vòng đời **plan → persist → build**: khi lập kế hoạch nó khám phá
codebase bằng `deep-exploration`, và sau khi bạn duyệt kế hoạch ("Implement the plan") nó lưu
kế hoạch vào `.claude/plans/<slug>.md` rồi thực thi bằng `parallel-execution`. Cơ chế này hoạt
động ở dạng *gợi ý* (instructions nằm trong context). Nếu muốn **đảm bảo chắc chắn**, repo có
sẵn ba hook (Claude Code) tại [`skills/senior-engineer/hooks/`](../skills/senior-engineer/hooks/):

- `plan_mode_prompt.py` — hook `UserPromptSubmit`: khi đang ở plan mode, nhắc agent dùng vòng
  đời `senior-engineer` (chỉ với task code/feature thực sự — task nhỏ/không phải code thì bỏ qua).
- `plan_approved.py` — hook `PostToolUse` khớp `ExitPlanMode`: kích hoạt **đúng lúc bạn duyệt
  kế hoạch**, nhắc lưu kế hoạch vào `.claude/plans/` rồi chạy `parallel-execution` (chỉ với thay
  đổi nhiều phần — thay đổi nhỏ thì build thẳng).
- `senior_engineer_explore_first.py` — hook `PostToolUse` khớp `Skill`: kích hoạt **đúng lúc
  `senior-engineer` được gọi**, ép tool-call **tiếp theo bắt buộc** phải là `Skill(deep-exploration)`
  (≥3 agent `Explore`) trước khi đọc file hay trả lời. Đây là cơ chế thực thi cho Step 0 — đóng
  lỗ hổng khi agent chỉ *kể* là sẽ khám phá rồi tự `ls`/`grep` inline (và fan-out thiếu, ví dụ chỉ
  2 agent) thay vì thật sự bàn giao.

Hai hook plan-mode đều **judgment-preserving**: không bao giờ ép fan-out cho một thay đổi tầm
thường. Ngược lại, `senior_engineer_explore_first.py` **cố ý không có ngoại lệ** — mỗi lần
`senior-engineer` hoạt động là nó luôn ép khám phá trước (đúng theo Step 0 "ALWAYS, no exceptions").
Để bật, thêm vào `~/.claude/settings.json` (đường dẫn theo bản cài mặc định của Claude Code):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "python3 ~/.claude/skills/senior-engineer/hooks/plan_mode_prompt.py", "timeout": 10 } ] }
    ],
    "PostToolUse": [
      { "matcher": "ExitPlanMode", "hooks": [ { "type": "command", "command": "python3 ~/.claude/skills/senior-engineer/hooks/plan_approved.py", "timeout": 10 } ] },
      { "matcher": "Skill", "hooks": [ { "type": "command", "command": "python3 ~/.claude/skills/senior-engineer/hooks/senior_engineer_explore_first.py", "timeout": 10 } ] }
    ]
  }
}
```

> **Lưu ý — gộp, đừng ghi đè.** Nếu `settings.json` của bạn đã có khối `"hooks"` (ví dụ hook
> âm thanh `Stop`/`Notification`), hãy **gộp** hai key `UserPromptSubmit` và `PostToolUse` ở trên
> vào khối `hooks` hiện có — đừng dán đè cả khối, nếu không bạn sẽ xóa mất các hook đang có. Nếu
> đã có sẵn `PostToolUse`, **thêm từng mục matcher** (`ExitPlanMode` và `Skill`) vào mảng thay vì
> thay thế.

> **Đường dẫn theo kiểu cài.** Snippet trên dùng đường dẫn của bản cài mặc định
> (`~/.claude/skills/...`). Nếu bạn cài theo dự án (`./scripts/install.sh --project`), đổi thành
> `./.claude/skills/senior-engineer/hooks/...`. Cần có `python3` trong PATH.

Hook chỉ được nạp lúc khởi động — sau khi sửa `settings.json`, **khởi động lại Claude Code**
(hoặc `/hooks`). Codex không dùng cơ chế hook này; với Codex chỉ có dạng *gợi ý* trong `SKILL.md`.

## `ship`

Chạy `/ship`. Mặc định tự động: đọc `AGENTS.md`, cắt nhánh mới từ nhánh phụ
(`develop`/`staging`), commit tất cả thay đổi, push và mở PR. Không bao giờ động vào
`main`/`master`. Chỉ dừng khi nghi ngờ có secret, push bị từ chối, hoặc xung đột chặn việc ship.

| Lệnh | Hành vi |
|---|---|
| `/ship` | branch → commit → push → PR |
| `/ship no pr` | dừng sau khi push, không mở PR |
| `/ship this chat` / `here` | chỉ ship file của phiên làm việc này |
| `/ship to <branch>` | nhắm tới một nhánh base cụ thể cho PR |
| `/ship from here` | ship nhánh hiện tại nguyên trạng |
| `/ship merge` | merge PR + chạy deploy production |
| `/ship review` | review diff sau khi ship |
| `/ship "thông điệp"` | dùng làm dòng tóm tắt commit |

Các chế độ có thể kết hợp (`/ship here no pr`). `/ship` thích nghi với bất kỳ quy ước nào bạn
nêu ra và đề nghị lưu vào `AGENTS.md`. Với repo Evovi, thả
[`templates/AGENTS.evovi.md`](../templates/AGENTS.evovi.md) vào để nó biết luồng `develop` +
dokploy ngay từ lần chạy đầu.

## Cập nhật & xử lý sự cố

- **Cập nhật:** `git pull`, sau đó chạy lại `./scripts/install.sh`.
- **Không thấy trong danh sách skill:** kiểm tra đường dẫn `~/.claude/skills/<name>/SKILL.md` (Claude Code) hoặc `~/.agents/skills/<name>/SKILL.md` (Codex) rồi khởi động lại.
- **`/ship` không mở được PR:** chạy `gh auth login`.
- **Sai nhánh base của PR:** thêm mục shipping vào `AGENTS.md` hoặc dùng `/ship to <branch>`.
