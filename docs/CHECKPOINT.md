# Checkpoint triển khai Paloria 3.0

## U0.3 — Git baseline và restore point

Trạng thái: `VERIFIED` ngày 2026-10-04.

### Mục tiêu và invariant

- Có lịch sử cục bộ trước khi refactor/migration hoặc di chuyển asset.
- Snapshot không chứa cache, build, log, translation artifact hoặc export.
- Việc tạo Git không thay đổi gameplay, asset path hay license status.

### Thay đổi

- Khởi tạo Git repository với branch `main`.
- Root commit `2c243e1` lưu 418 file baseline đã audit.
- Tag `baseline-u0.3` đánh dấu checkpoint sau tài liệu version-control.
- `docs/process/VERSION_CONTROL.md` ghi branch workflow, commit convention và phục hồi không dùng reset phá hủy.
- Không cấu hình remote và không push dữ liệu ra ngoài máy.

### Validation

- Staging audit: 418 file; 0 file thuộc `.godot`, `build`, log, translation artifact, `node_modules`, export hoặc cache.
- `git fsck --full` và detached worktree restore test từ tag phải thành công.
- Gate chính: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1`.
- Documentation: 16 file bắt buộc; asset integrity 166/166; Godot editor-load và smoke exit 0.

### Compatibility và rủi ro

- Save/data/gameplay breaking change: none.
- Repository chỉ ở local; hỏng/mất ổ D vẫn có thể làm mất cả working tree và `.git`.
- Commit baseline dùng identity cục bộ trung lập vì global Git email chưa cấu hình.
- 166 asset vẫn `QUARANTINE/UNKNOWN`; Git tracking không xác nhận quyền phân phối.
- `game-dev` CLI vẫn thiếu; chưa download/admit asset mới.

### Gói tiếp theo

U0.4: phân loại 166 asset theo `keep-and-verify`, `replace`, `remove-later`, ưu tiên 69 asset runtime; lập mapping replacement nhưng chưa di chuyển/xóa. Sau U0.4 bắt đầu U1.1 Core IDs/registry trên branch riêng.

## Lịch sử

- U0.2: manifest 166 asset, documentation/module/gameplay catalog và validation gates; `VERIFIED` ngày 2026-10-04.
- U0.1: sửa `is_sprinting`, audio lifecycle và tạo Godot headless editor/smoke gate; `VERIFIED` ngày 2026-10-04.
