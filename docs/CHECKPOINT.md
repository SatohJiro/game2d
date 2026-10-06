# Checkpoint triển khai Paloria 3.0

## U1.12h — typed cooking-pot processing persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Save/load giữa mẻ giữ đúng recipe đã trừ nguyên liệu, future output và timer của player-created cooking pot.
- Save chỉ dùng stable recipe ID; không serialize runtime recipe Dictionary, localized text, Node hoặc Callable.
- Invalid recipe/progress bị reject trước mutation; không đổi recipe, cost, yield hoặc duration.

### Kết quả đã triển khai

- Thêm `CookingRecipeCatalog` cho năm `recipe.cooking.*` và mapping tới legacy runtime rows.
- Thêm `CookingPotPlacementState` gồm recipe ID và remaining seconds với duration validation.
- Cooking pot restore resolve lại recipe runtime, suy ra `is_cooking` và không trừ nguyên liệu lần hai.
- Placement record, Player snapshot và staged apply dispatch state đúng subtype; record cũ thiếu state thành idle.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh.
- Regression giữ `recipe.cooking.hearty_stew`, đúng future output và timer 1,75 giây qua apply/snapshot/apply; legacy ID và timer vượt duration bị reject.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; cooking-pot record cũ thiếu state load thành idle.
- Asset/provenance: none.
- Compost/ranch/crop và building health chưa persist.
- Rollback: revert cooking catalog/state, record dispatch, Player/cooking bridge, regression và docs U1.12h.

### Gói tiếp theo

U1.12i persist riêng compost processing state theo `NEXT_UPDATE_PROMPT.md`.
