# Evovi Skills

Các skill [Claude Code](https://claude.com/claude-code) dành cho kỹ sư của Evovi.

> **Chỉ dùng nội bộ.** Các skill này mã hóa quy ước kỹ thuật của Evovi và chỉ dành cho nhân
> sự Evovi sử dụng trong các dự án của Evovi. Không phân phối ra bên ngoài.

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
./scripts/install.sh             # toàn cục  -> ~/.claude/skills
./scripts/install.sh --project   # theo dự án -> ./.claude/skills
```

Khởi động lại Claude Code, chạy `/help` và xác nhận cả hai skill xuất hiện. Bảo trì skill?
Xem [CONTRIBUTING.md](CONTRIBUTING.md).

## Tài liệu

**→ [Hướng dẫn sử dụng đầy đủ](docs/USAGE.md)** — các cách cài đặt, điều kiện kích hoạt, tất cả chế độ của `/ship` và xử lý sự cố.

Với các repo của Evovi, thả [`templates/AGENTS.evovi.md`](templates/AGENTS.evovi.md) vào dự án
dưới tên `AGENTS.md` để `/ship` tự động theo luồng `develop` + deploy dokploy.

## Cấu trúc

```
skills/
  senior-engineer/SKILL.md   # persona + bộ định tuyến
  ship/SKILL.md              # pipeline ship
docs/USAGE.md                # hướng dẫn sử dụng
templates/AGENTS.evovi.md    # AGENTS.md mẫu cho repo Evovi
```
