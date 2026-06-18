# Evovi Agent Skills

Agent skills cho kỹ sư Evovi — tương thích với [Claude Code](https://claude.com/claude-code)
và [Codex](https://developers.openai.com/codex) (cùng chuẩn `SKILL.md`).

> Evovi là một công ty số hóa của Việt Nam — mọi tài liệu và giao tiếp đều bằng tiếng Việt.
> Xem [AGENTS.md](AGENTS.md).

## Các skill

| Skill | Mục đích |
|---|---|
| [`senior-engineer`](skills/senior-engineer/SKILL.md) | Persona kỹ sư cấp cao + bộ định tuyến. Cân nhắc khả năng mở rộng (scalability) trong mọi quyết định về backend/DB/schema và định tuyến công việc tới skill chuyên biệt phù hợp. |
| [`ship`](skills/ship/SKILL.md) | Pipeline một lệnh: branch → commit → push → PR, kèm tùy chọn merge + deploy. Mặc định theo luồng nhánh `develop` của Evovi và không bao giờ động vào `main`. |

## Bắt đầu nhanh

```bash
git clone https://github.com/daobinhgiang/evo-artifact.git && cd evo-artifact
./scripts/install.sh             # cả hai: ~/.claude/skills + ~/.agents/skills
./scripts/install.sh --claude    # chỉ Claude Code
./scripts/install.sh --codex     # chỉ Codex
./scripts/install.sh --project   # theo dự án: ./.claude/skills + ./.agents/skills
```

Khởi động lại agent, rồi `/help` (Claude Code) hoặc `/skills` (Codex) để xác nhận. Bảo trì
skill? Xem [CONTRIBUTING.md](CONTRIBUTING.md).

## Tài liệu

**→ [Hướng dẫn sử dụng đầy đủ](docs/USAGE.md)** — cài đặt cho Claude Code & Codex, điều kiện kích hoạt, tất cả chế độ của `/ship` và xử lý sự cố.

Với các repo của Evovi, thả [`templates/AGENTS.evovi.md`](templates/AGENTS.evovi.md) vào dự án
dưới tên `AGENTS.md` để `/ship` tự động theo luồng `develop` + deploy dokploy.

## Cấu trúc

```
skills/
  senior-engineer/SKILL.md   # persona + bộ định tuyến
  ship/SKILL.md              # pipeline ship
docs/USAGE.md                # hướng dẫn sử dụng
templates/AGENTS.evovi.md    # AGENTS.md mẫu cho repo Evovi
scripts/install.sh           # cài cho Claude Code và/hoặc Codex
```
