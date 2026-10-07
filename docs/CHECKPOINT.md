# Checkpoint triển khai Paloria 3.0

## U1.12n — chest durability persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Chest save/load giữ inventory và health đã commit trong cùng typed state.
- Restore health qua lifecycle `_ready()` nhưng không gọi damage, destruction, reward hay presentation path.
- Health ngoài 1–250 fail trước mutation; inventory capacity/economy và max health giữ nguyên.

### Kết quả đã triển khai

- Mở rộng `ChestPlacementState` với health nguyên 1–250; DTO inventory-only cũ mặc định 250.
- Chest staged apply dùng pending health để `_ready()` không reset state đã restore.
- Inventory được validate trên shadow store trước khi health/runtime store cùng commit.
- Regression apply/snapshot/apply giữ 17 wood, 4 berry và 137 health; health 0 giữ nguyên runtime cũ.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh; chỉ còn cảnh báo môi trường CA/log `user://` đã biết.
- Regression apply/snapshot/apply giữ inventory + 137 health; health 0 bị reject trước runtime replacement.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; chest state inventory-only cũ load health 250.
- Asset/provenance: none.
- Health của building ngoài chest và resource depletion chưa persist.
- Rollback: revert chest health/pending lifecycle, regression và docs U1.12n.

### Gói tiếp theo

U1.12o persist riêng furnace durability theo `NEXT_UPDATE_PROMPT.md`.
