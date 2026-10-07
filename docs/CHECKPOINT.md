# Checkpoint triển khai Paloria 3.0

## U1.12m — typed turret cooldown persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Turret save/load giữ đúng cooldown còn lại mà không tạo phát bắn khi restore.
- Target Node, Callable, projectile và tween không đi qua DTO; targeting được tìm mới ở runtime.
- Invalid/non-finite/out-of-range cooldown fail trước mutation; damage/range/fire-rate/targeting giữ nguyên.

### Kết quả đã triển khai

- Thêm `TurretPlacementState` với đúng một scalar `cooldown_remaining` trong `[0, 1.25]`.
- `BuildingTurret` có typed create/apply boundary; apply chỉ gán cooldown và không gọi fire path.
- Player staged restore/snapshot dispatch turret state như các subtype đã admit.
- Regression xác nhận DTO chỉ có cooldown và apply/snapshot/apply giữ `0.8` giây.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh; chỉ còn cảnh báo môi trường CA/log `user://` đã biết.
- Regression apply/snapshot/apply giữ cooldown `0.8`; cooldown `1.26` bị reject trước mutation.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; turret record cũ thiếu state load cooldown 0.
- Asset/provenance: none.
- Building health và resource depletion chưa persist.
- Rollback: revert turret state, Player dispatch, regression và docs U1.12m.

### Gói tiếp theo

U1.12n persist riêng chest durability theo `NEXT_UPDATE_PROMPT.md`.
