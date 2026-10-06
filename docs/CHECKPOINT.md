# Checkpoint triển khai Paloria 3.0

## U1.12i — typed compost processing persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Save/load giữa mẻ giữ đúng material đã nạp, fertilizer chờ nhận và timer của player-created compost bin.
- Không trừ hoặc cộng item lần hai; không serialize Node/Callable hay presentation state.
- Invalid count/progress bị reject trước mutation; không đổi capacity, output hoặc thời gian 8 giây.

### Kết quả đã triển khai

- Thêm `CompostBinPlacementState` với material 0–10, output không âm và timer `[0,8)`.
- Timer dương bắt buộc còn material; state rỗng tương thích record cũ.
- Placement record, Player snapshot và staged apply dispatch state đúng subtype compost.
- Restore gán committed state đúng một lần và giữ nguyên gameplay hiện hữu.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh.
- Regression giữ 6 material, 4 fertilizer và timer 3,25 giây qua apply/snapshot/apply; over-capacity và progress không có material bị reject.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; compost record cũ thiếu state load thành rỗng.
- Asset/provenance: none.
- Ranch/crop và building health chưa persist.
- Rollback: revert compost state model, record dispatch, Player/compost bridge, regression và docs U1.12i.

### Gói tiếp theo

U1.12j audit và persist riêng ranch state theo `NEXT_UPDATE_PROMPT.md`.
