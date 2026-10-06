# Checkpoint triển khai Paloria 3.0

## U1.11d — atomic JSON save repository

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Chỉ ghi/promote Save v1 đã validate; temporary cũng phải đọc/validate lại trước commit.
- Replacement giữ primary trước đó làm backup; primary hỏng không được ghi đè backup hợp lệ.
- Read recovery không mutate file. Chưa autosave, migration hoặc UI slot.

### Kết quả đã triển khai

- Thêm `SaveRepository/Result` với typed status cho save/load/not-found/invalid/I/O/recovered-backup.
- Ghi temporary + flush + verify, rotate primary hợp lệ sang backup, promote bằng rename và có best-effort rollback.
- Load ưu tiên primary; primary thiếu/hỏng dùng backup hợp lệ và trả trạng thái recovery rõ ràng.
- Thêm focused validator cô lập vào full project gate.

### Validation hiện tại

- Baseline full gate xanh.
- Focused repository regression xanh: first write/read, deep-copy, invalid no-mutation, replacement backup, corrupt-primary recovery và save-after-recovery.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset gates, editor import/load, gameplay validators, Save schema và Save repository đều đạt.

### Compatibility, asset và giới hạn

- Save schema vẫn v1; chưa có file phát hành cần migration. Không thêm/thay asset.
- Chưa checksum/encryption; atomicity dựa trên same-directory rename và một backup.
- Rollback: revert U1.11d; schema và runtime adapters U1.11a–c không phụ thuộc repository.

### Gói tiếp theo

U1.11e tạo migration registry/harness fail-closed cho version routing, chưa thêm migration dữ liệu giả hoặc UI/autosave. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
