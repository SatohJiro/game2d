# Checkpoint triển khai Paloria 3.0

## U1.12s — turret structure durability persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Turret save/load giữ cooldown và structure health trong cùng typed state.
- Restore không gọi targeting/fire/destruction và không serialize target/projectile runtime.
- Health ngoài 1–350 fail trước mutation; damage/range/fire-rate/targeting giữ nguyên.

### Kết quả đã triển khai

- Mở rộng `TurretPlacementState` bằng health nguyên 1–350; DTO cooldown-only cũ mặc định 350.
- Turret staged apply dùng pending health để `_ready()` không reset state đã restore.
- DTO mới chỉ có cooldown/health scalar; target/projectile/tween không đi qua save.
- Regression giữ cooldown 0.8 và 223 HP; health 351 giữ runtime cũ.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh; chỉ còn cảnh báo môi trường CA/log `user://` đã biết.
- Regression apply/snapshot/apply giữ cooldown + 223 health; health 351 bị reject trước runtime replacement.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; turret cooldown-only state cũ load health 350.
- Asset/provenance: none.
- Workbench health chưa persist; compost/farm plot chưa có durability runtime; resource depletion chưa persist.
- Rollback: revert turret health/pending lifecycle, regression và docs U1.12s.

### Gói tiếp theo

U1.12t persist riêng workbench durability theo `NEXT_UPDATE_PROMPT.md`.
