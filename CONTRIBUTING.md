# Đóng góp

Dành cho kỹ sư Evovi bảo trì các skill này.

## Quy trình

- Cắt nhánh từ `develop`; mở PR ngược lại vào `develop`. Không bao giờ commit vào `main`.
- Chạy `./scripts/install.sh` để thử thay đổi tại máy trước khi push.
- CI (`validate-skills`) kiểm tra mỗi `skills/*/SKILL.md` có đủ `name`, `description`, `version`.

## Chỉnh sửa một skill

- Sửa `skills/<name>/SKILL.md`. Giữ nguyên phần frontmatter YAML.
- **Tăng `version:`** mỗi khi thay đổi hành vi (theo semver).
- Cập nhật `evals/evals.json` khi thay đổi điều kiện kích hoạt hoặc hành vi.
- Giữ `description:` chính xác — đây là yếu tố quyết định khi nào skill được kích hoạt.
- Giữ nguyên tiếng Anh cho `SKILL.md` (xem [AGENTS.md](AGENTS.md)) — chúng kích hoạt bằng cụm tiếng Anh.

## Tài liệu

Giữ `README.md` và `docs/USAGE.md` đồng bộ với hành vi của skill. Tài liệu viết bằng **tiếng
Việt** và ngắn gọn.
