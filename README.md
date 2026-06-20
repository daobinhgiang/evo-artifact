# Evovi Agent Skills

Agent skills cho kỹ sư Evovi — tương thích với [Claude Code](https://claude.com/claude-code)
và [Codex](https://developers.openai.com/codex) (cùng chuẩn `SKILL.md`).

> **Chỉ dùng nội bộ.** Các skill này mã hóa quy ước kỹ thuật của Evovi và chỉ dành cho nhân
> sự Evovi sử dụng trong các dự án của Evovi. Không phân phối ra bên ngoài.

> Evovi là một công ty số hóa của Việt Nam — mọi tài liệu và giao tiếp đều bằng tiếng Việt.
> Xem [AGENTS.md](AGENTS.md).

## Các skill

| Skill | Mục đích |
|---|---|
| [`senior-engineer`](skills/senior-engineer/SKILL.md) | Persona kỹ sư cấp cao + bộ định tuyến. Cân nhắc khả năng mở rộng (scalability) trong mọi quyết định về backend/DB/schema và định tuyến công việc tới skill chuyên biệt phù hợp. |
| ↳ [`deep-exploration`](skills/deep-exploration/SKILL.md) | Khám phá codebase theo kiểu chia-để-trị bằng nhiều subagent `Explore` song song. Là engine đứng sau nhiều skill khác. |
| ↳ [`parallel-execution`](skills/parallel-execution/SKILL.md) | Thực thi một kế hoạch đã duyệt bằng cách chia việc ra nhiều builder song song, kèm tester kiểm tra từng phần. |
| ↳ [`code-quality-review`](skills/code-quality-review/SKILL.md) | Review chất lượng có giới hạn (một diff / PR / file / function): verdict + phân loại mức độ. Giữ bộ `references/` dùng chung. |
| ↳ [`codebase-review`](skills/codebase-review/SKILL.md) | Audit toàn bộ codebase theo nhiều pha (explore → research → deep-dive → báo cáo). |
| ↳ [`codebase-wide-change`](skills/codebase-wide-change/SKILL.md) | Áp một thay đổi nhất quán trên toàn repo, không bỏ sót file nào. |
| ↳ [`codex-triage`](skills/codex-triage/SKILL.md) | Phân loại comment review tự động của Codex trên PR: Fix Now / Fix Later / Dismiss. |
| [`ship`](skills/ship/SKILL.md) | Pipeline một lệnh: branch → commit → push → PR, kèm tùy chọn merge + deploy. Mặc định theo luồng nhánh `develop` của Evovi và không bao giờ động vào `main`. |
| [`test`](skills/test/SKILL.md) | QA tính năng trên trình duyệt thật: chạy nhiều Playwright MCP server song song, mỗi flow một subagent. Enumerate ca kiểm thử vào `TEST_MATRIX.md`, fan-out kiểm thử đồng thời rồi tổng hợp báo cáo. Cần Playwright MCP — `install.sh --playwright` thiết lập sẵn. |

> Sáu skill có dấu **↳** là *họ skill* mà `senior-engineer` định tuyến tới. `senior-engineer`
> là bộ định tuyến — nếu thiếu chúng thì các lệnh `Skill(...)` của nó sẽ lỗi. Vì vậy hãy luôn
> **cài cả họ cùng nhau** (`install.sh` đã làm sẵn việc này).

## Bắt đầu nhanh

Cài một dòng, không cần clone (yêu cầu có `git`):

```bash
curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash                 # cả hai: ~/.claude/skills + ~/.agents/skills
curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash -s -- --claude  # chỉ Claude Code
curl -fsSL https://raw.githubusercontent.com/daobinhgiang/evo-artifact/main/scripts/install.sh | bash -s -- --codex   # chỉ Codex
```

Script tự tải repo về thư mục tạm rồi copy skills vào đích. Tham số đặt sau `bash -s --`.

Hoặc clone rồi chạy (thêm `--project` để cài theo dự án vào `./.claude/skills` + `./.agents/skills`):

```bash
git clone https://github.com/daobinhgiang/evo-artifact.git && cd evo-artifact
./scripts/install.sh             # cả hai: ~/.claude/skills + ~/.agents/skills
./scripts/install.sh --claude    # chỉ Claude Code
./scripts/install.sh --codex     # chỉ Codex
./scripts/install.sh --project   # theo dự án: ./.claude/skills + ./.agents/skills
./scripts/install.sh --playwright # cài skills + thêm Playwright MCP server cho /test (mặc định 5; --playwright=7 cho 7)
```

Skill `/test` cần nhiều **Playwright MCP server isolated** chạy song song. Thêm `--playwright` (hoặc
`--playwright=N`) để installer tự chạy `claude mcp add` cho `playwright`, `playwright2`, … (cần có
`claude` CLI). Xem [`skills/test/references/mcp-setup.md`](skills/test/references/mcp-setup.md) nếu
muốn cấu hình thủ công.

Khởi động lại agent, rồi `/help` (Claude Code) hoặc `/skills` (Codex) để xác nhận. Bảo trì
skill? Xem [CONTRIBUTING.md](CONTRIBUTING.md).

## Tài liệu

**→ [Hướng dẫn sử dụng đầy đủ](docs/USAGE.md)** — cài đặt cho Claude Code & Codex, điều kiện kích hoạt, tất cả chế độ của `/ship` và xử lý sự cố.

Với các repo của Evovi, thả [`templates/AGENTS.evovi.md`](templates/AGENTS.evovi.md) vào dự án
dưới tên `AGENTS.md` để `/ship` tự động theo luồng `develop` + deploy dokploy.

## Cấu trúc

```
skills/
  senior-engineer/             # persona + bộ định tuyến
    SKILL.md
    hooks/                     # (tùy chọn, chỉ Claude Code) tự động hóa plan mode
  deep-exploration/SKILL.md    # khám phá codebase song song (engine dùng chung)
  parallel-execution/SKILL.md  # thực thi kế hoạch song song
  code-quality-review/         # review chất lượng có giới hạn + references/ dùng chung
  codebase-review/SKILL.md     # audit toàn bộ codebase
  codebase-wide-change/SKILL.md # thay đổi nhất quán toàn repo
  codex-triage/SKILL.md        # phân loại review của Codex
  ship/SKILL.md                # pipeline ship
  test/SKILL.md                # QA trình duyệt song song (Playwright MCP)
docs/USAGE.md                  # hướng dẫn sử dụng
templates/AGENTS.evovi.md      # AGENTS.md mẫu cho repo Evovi
scripts/install.sh             # cài cho Claude Code và/hoặc Codex
```
