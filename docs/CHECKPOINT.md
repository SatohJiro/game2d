# Checkpoint triển khai Paloria 3.0

## U1.11f — explicit runtime save coordinator

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Kết nối snapshot → repository khi save và repository → migration → apply khi load.
- Stage lỗi dừng pipeline; repository/migration failure không mutate runtime.
- Phản ánh primary/backup source và handoff world clock. Chưa autosave/UI/pause policy.

### Kết quả đã triển khai

- Thêm `SaveCoordinator/Result` với typed stage failure và upstream status/errors.
- Explicit save/load không giữ state gameplay; caller sở hữu thời điểm gọi và world clock commit.
- Thêm scene-level Player round-trip validator vào full project gate.

### Validation hiện tại

- Baseline full gate xanh.
- Focused regression xanh: primary round-trip, backup recovery/source/clock và corrupt-both no-mutation.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset gates, editor import/load, gameplay validators và toàn bộ Save validators đều đạt.

### Compatibility, asset và giới hạn

- Save schema vẫn v1; production migration registry rỗng. Không thêm/thay asset.
- Chưa lưu world entity/base/building/crop/quest; pet rarity/trait và inactive stance vẫn là gap đã biết.
- Rollback: revert U1.11f; các boundary U1.11a–e vẫn độc lập.

### Gói tiếp theo

U1.12a audit persistence coverage của vertical slice và chốt typed ownership/ID cho gap có mất dữ liệu cao nhất trước khi mở U2. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
