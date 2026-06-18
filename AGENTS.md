# AGENTS.md

Hướng dẫn cho các AI agent (và con người) làm việc trong repo này.

## Về Evovi

Evovi là một **công ty số hóa của Việt Nam** (Vietnamese digitalization company). Mọi sản
phẩm, tài liệu và giao tiếp đều hướng tới người dùng Việt Nam.

## Ngôn ngữ — BẮT BUỘC tiếng Việt

**Mọi thứ phải bằng tiếng Việt.** Toàn bộ tài liệu (`README.md`, `docs/`, `CONTRIBUTING.md`,
template, mô tả PR, commit message ở phần diễn giải, trao đổi với người dùng) phải được viết
bằng tiếng Việt.

**Ngoại lệ:** các file `skills/*/SKILL.md` giữ nguyên tiếng Anh — đây là phần *chỉ dẫn chức
năng* cho Claude Code và được kích hoạt bằng các cụm tiếng Anh (ví dụ `/ship`, "act as a
senior engineer"). Dịch chúng sẽ làm hỏng cơ chế kích hoạt skill. Thuật ngữ kỹ thuật phổ biến
(branch, commit, PR, deploy, skill...) có thể giữ nguyên tiếng Anh khi viết tài liệu tiếng Việt.

## Quy ước ship (cho repo này)

- **Nhánh chính:** `main` — được bảo vệ, không commit/push/PR trực tiếp.
- **Nhánh phụ:** `develop` — nhánh tích hợp, mọi thay đổi vào qua PR.
- **PR base:** `develop`.
- **Merge:** squash.

## Tài liệu

- [README.md](README.md) — giới thiệu, cài đặt nhanh.
- [docs/USAGE.md](docs/USAGE.md) — hướng dẫn sử dụng đầy đủ.
- [CONTRIBUTING.md](CONTRIBUTING.md) — quy trình bảo trì skill.
