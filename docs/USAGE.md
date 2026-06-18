# Hướng dẫn sử dụng Evovi Skills

Cài đặt và sử dụng hai skill [Claude Code](https://claude.com/claude-code) trong repo này:
**`senior-engineer`** và **`ship`**. Chỉ dùng nội bộ Evovi — xem [README](../README.md).

| Skill | Chức năng |
|---|---|
| **`senior-engineer`** | Persona kỹ sư cấp cao + bộ định tuyến. Định hình cách Claude tư duy về kỹ thuật, cân nhắc khả năng mở rộng trong mọi quyết định backend/DB/schema, và định tuyến tới các skill chuyên biệt (review code, audit, refactor toàn app, khám phá sâu, plan→build). |
| **`ship`** | Pipeline một lệnh: branch → commit → push → PR, kèm tùy chọn merge + deploy. Đọc `AGENTS.md` của từng repo, cắt nhánh mới từ `develop`/`staging`, không động vào `main`. |

## Cài đặt

Toàn cục (cho từng kỹ sư):

```bash
git clone https://github.com/daobinhgiang/evo-artifact.git && cd evo-artifact
mkdir -p ~/.claude/skills && cp -R skills/senior-engineer skills/ship ~/.claude/skills/
```

Theo dự án (repo dùng chung) — copy vào `.claude/skills/` rồi commit:

```bash
mkdir -p .claude/skills && cp -R /path/to/evo-artifact/skills/* .claude/skills/
```

Kiểm tra: khởi động lại Claude Code, chạy `/help` và xác nhận cả hai skill được liệt kê.

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

> Các skill được định tuyến tới là **riêng biệt** và không đi kèm trong repo này.
> `senior-engineer` vẫn hoạt động độc lập như một persona; cài thêm các skill kia để dùng đầy
> đủ tính năng định tuyến.

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

- **Cập nhật:** `git pull`, sau đó copy lại các thư mục `skills/*`.
- **Không thấy trong `/help`:** kiểm tra đường dẫn là `~/.claude/skills/<name>/SKILL.md` rồi khởi động lại.
- **`/ship` không mở được PR:** chạy `gh auth login`.
- **Sai nhánh base của PR:** thêm mục shipping vào `AGENTS.md` hoặc dùng `/ship to <branch>`.
