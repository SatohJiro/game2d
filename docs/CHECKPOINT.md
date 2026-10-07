# Checkpoint triển khai Paloria 3.0

## U1.12k — typed farm-plot persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Save/load giữ crop, stage, growth, moisture, watered và fertilizer state mà không reset progress hoặc tạo harvest.
- Save dùng stable crop/stage ID; enum số, localized text và Node không vượt boundary.
- Invalid crop/stage/progress fail trước mutation; farming timing/economy giữ nguyên.

### Kết quả đã triển khai

- Thêm typed `crop.golden_wheat` và `crop.pal_herb`; registry hiện có 42 definitions.
- Thêm `FarmPlotCatalog` mapping ba crop và bốn `farm.stage.*` sang enum compatibility.
- Thêm `FarmPlotPlacementState` với stage/progress và moisture/water coherence validation.
- ResourceNode snapshot/apply state không chạy growth tick hoặc harvest side effect.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load, focused content validation và `validate_save_schema.gd` xanh.
- Regression giữ wheat GROWING, timer 7,25, moisture 64, watered/fertilized qua apply/snapshot/apply; localized crop và stage/progress sai bị reject.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset gates, 42 content definitions, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; farm record cũ thiếu state load thành EMPTY.
- Asset/provenance: không thêm asset; definitions tham chiếu item/assets baseline vẫn quarantine.
- Health, altar/turret và tree/rock depletion chưa persist.
- Rollback: revert crop definitions, farm catalog/state, record/ResourceNode/Player bridge, validators và docs U1.12k.

### Gói tiếp theo

U1.12l audit và persist riêng altar lifecycle theo `NEXT_UPDATE_PROMPT.md`.
