# AGENTS.md

Thả file này vào một repo dự án của Evovi dưới tên `AGENTS.md` để `/ship` theo đúng quy ước
Evovi ngay từ lần chạy đầu. Sửa các phần placeholder cho khớp với dự án cụ thể.

## Ngôn ngữ

Evovi là công ty số hóa của Việt Nam — mọi tài liệu, commit message (phần diễn giải) và giao
tiếp đều bằng **tiếng Việt**.

## Shipping

- **Nhánh chính:** `main` — được bảo vệ, không commit/push/PR trực tiếp.
- **Nhánh phụ:** `develop` — nhánh tích hợp. Mọi thay đổi vào qua PR từ nhánh ngắn hạn.
- **Đặt tên nhánh:** `feat/<slug>`, `fix/<slug>`, hoặc `ship/<slug>`.
- **PR base:** `develop`.
- **Chiến lược merge:** squash.

## Production Deploy

Merge vào `develop` sẽ deploy lên môi trường dokploy (`dokploy.test.evovi.vn`).

### Migration
```bash
# <lệnh migration của dự án, ví dụ npm run migrate>
```

### Kiểm tra
```bash
# <lệnh hoặc URL health-check>
```
