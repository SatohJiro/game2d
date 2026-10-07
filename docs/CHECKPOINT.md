# Checkpoint triển khai Paloria 3.0

## U1.12o — furnace durability persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Furnace save/load giữ input/output/progress và health đã commit trong cùng typed state.
- Restore qua `_ready()` nhưng không gọi smelting tick, damage, destruction, reward hay presentation path.
- Health ngoài 1–300 fail trước mutation; smelting timer/economy và max health giữ nguyên.

### Kết quả đã triển khai

- Mở rộng `FurnacePlacementState` với health nguyên 1–300; DTO processing-only cũ mặc định 300.
- Furnace staged apply dùng pending health để `_ready()` không reset state đã restore.
- Processing state và health được validate trước khi runtime replacement.
- Regression giữ 4 ore, 2 wood, 3 iron, 1 pal, timer 2.25 và 181 health; health 301 giữ runtime cũ.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh; chỉ còn cảnh báo môi trường CA/log `user://` đã biết.
- Regression apply/snapshot/apply giữ processing + 181 health; health 301 bị reject trước runtime replacement.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; furnace state năm field cũ load health 300.
- Asset/provenance: none.
- Health của building ngoài chest/furnace và resource depletion chưa persist.
- Rollback: revert furnace health/pending lifecycle, regression và docs U1.12o.

### Gói tiếp theo

U1.12p persist riêng cooking-pot durability theo `NEXT_UPDATE_PROMPT.md`.
