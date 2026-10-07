# Checkpoint triển khai Paloria 3.0

## U1.12q — ranch durability persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Ranch save/load giữ assignments/food/production timer/health trong cùng typed state.
- Restore dựng đúng animal presentation nhưng không chạy production, consume food, reward hay destruction.
- Health ngoài 1–350 fail trước mutation; assignment/production economy và max health giữ nguyên.

### Kết quả đã triển khai

- Mở rộng `RanchPlacementState` với health nguyên 1–350; DTO ba field cũ mặc định 350.
- Ranch staged apply dùng pending health để `_ready()` không reset state đã restore.
- Stable assignments dựng đúng hai animal presentation Node nhưng Node không đi qua DTO.
- Regression giữ 13 food, hai assignment, timer 4.5 và 219 HP; health 351 giữ runtime cũ.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh; chỉ còn cảnh báo môi trường CA/log `user://` đã biết.
- Regression apply/snapshot/apply giữ ranch state + 219 health; health 351 bị reject trước runtime replacement.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; ranch state ba field cũ load health 350.
- Asset/provenance: none.
- Health của altar/turret/workbench chưa persist; compost/farm plot chưa có durability runtime; resource depletion chưa persist.
- Rollback: revert ranch health/pending lifecycle, regression và docs U1.12q.

### Gói tiếp theo

U1.12r persist riêng altar structure durability theo `NEXT_UPDATE_PROMPT.md`.
