# Checkpoint triển khai Paloria 3.0

## U1.12g — typed furnace processing persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Save/load giữa mẻ giữ đúng committed input, output chờ nhận và timer của player-created furnace.
- Không trừ hoặc cộng item lần hai; không persist Node, localized text, presentation state hoặc Flam boost.
- Payload bất nhất bị reject trước runtime mutation; không đổi recipe, tốc độ hoặc economy.

### Kết quả đã triển khai

- Thêm `FurnacePlacementState` typed với ore/wood, iron/pal output và timer `[0, 5)`.
- Timer dương bắt buộc còn batch hợp lệ; `is_smelting` được suy ra khi restore, boost được tính lại theo môi trường.
- Placement record, Player snapshot và staged apply dispatch state đúng subtype furnace.
- Record furnace cũ thiếu state tương thích thành furnace rỗng.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh.
- Regression giữ chính xác 4 ore, 2 wood, 3 iron, 1 pal ingot và timer 2,25 giây qua apply/snapshot/apply; progress không có batch bị reject.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; furnace record cũ thiếu state load thành rỗng.
- Asset/provenance: none.
- Furnace health, cooking/compost/ranch/crop state chưa persist.
- Rollback: revert furnace state model, record dispatch, Player/furnace bridge, regression và docs U1.12g.

### Gói tiếp theo

U1.12h persist riêng cooking-pot processing state theo `NEXT_UPDATE_PROMPT.md`.
