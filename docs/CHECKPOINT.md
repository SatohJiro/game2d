# Checkpoint triển khai Paloria 3.0

## U1.12j — typed ranch persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Save/load giữ food, production progress và assignment đúng một lần.
- Persist stable assignment/species identity; runtime animal Node/behavior và localized name chỉ là presentation.
- Invalid/duplicate identity hoặc progress bị reject trước mutation; không đổi production/economy/timing.

### Kết quả đã triển khai

- Thêm `RanchPlacementState` cho food, tối đa hai assignments và timer `[0,10)`.
- Owned pet dùng `pet.instance_*`; resident mặc định dùng `ranch.resident_starter` trong building record.
- Ranch restore dựng runtime species snapshots rồi `_ready` tạo lại animal presentation nodes.
- Placement record, Player snapshot và staged apply dispatch state đúng subtype ranch.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh.
- Regression giữ 13 food, hai stable assignments và timer 4,5 giây qua apply/snapshot/apply; đúng hai animal Node được dựng lại, identity localized/trùng bị reject.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; ranch record cũ thiếu state tái lập starter Slime.
- Asset/provenance: none.
- Crop, health, altar/turret state chưa persist; assignment reservation hai chiều với roster thuộc U5 jobs.
- Rollback: revert ranch state model/identity bridge, record dispatch, Player/ranch persistence, regression và docs U1.12j.

### Gói tiếp theo

U1.12k persist riêng farm-plot state theo `NEXT_UPDATE_PROMPT.md`.
