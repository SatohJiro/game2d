# Checkpoint triển khai Paloria 3.0

## U1.12f — typed chest inventory persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Save/load giữ đúng inventory đã commit của player-created chest, không cộng dồn hoặc làm mất item.
- DTO chỉ dùng stable item ID; localized key và Node/Callable không vượt persistence boundary.
- Restore state được kiểm tra off-tree trước khi thay world; không đổi capacity/economy/interaction rule.

### Kết quả đã triển khai

- Thêm `ChestPlacementState` typed cho wood, pal ore và berry.
- `BuildingPlacementRecord.state` validate theo subtype; state trên subtype chưa admit bị reject, chest record U1.12e thiếu state tương thích thành rỗng.
- Player snapshot chiếu state live đúng lúc save; chest restore dùng shadow store và transaction capacity trước commit.
- Audit mutable state còn lại được ghi trong `BUILDING_PLACEMENT_CONTRACT.md`; U1.12f chỉ chọn chest.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh.
- Regression chứng minh chest 17 wood + 4 berry qua snapshot/apply lặp lại vẫn đúng count; invalid item/state sai subtype bị reject.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; chest record cũ thiếu state load thành chest rỗng.
- Asset/provenance: none.
- Chest health và furnace/cooking/compost/ranch/crop state chưa persist.
- Rollback: revert chest state model, record state field, Player snapshot/apply bridge, regression và docs U1.12f.

### Gói tiếp theo

U1.12g persist riêng furnace processing state theo `NEXT_UPDATE_PROMPT.md`.
