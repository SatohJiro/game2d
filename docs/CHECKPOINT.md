# Checkpoint triển khai Paloria 3.0

## U1.12t — workbench durability persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Workbench save/load giữ structure health bằng typed state và stable `building.workbench`.
- Restore không gọi interaction/crafting/destruction và không serialize runtime references.
- Health ngoài 1–200 fail trước mutation; damage/crafting/progression giữ nguyên.

### Kết quả đã triển khai

- Thêm `WorkbenchPlacementState` với duy nhất health nguyên 1–200; state rỗng cũ mặc định 200.
- Admit scene dưới stable ID trong placement catalog nhưng không mở recipe/unlock xây workbench mới.
- Workbench staged apply dùng pending health để `_ready()` không reset state đã restore.
- Regression giữ 137 HP qua apply/snapshot/apply; health 201 giữ runtime cũ.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh.
- Regression apply/snapshot/apply giữ 137 health; health 201 bị reject trước runtime replacement; empty state chuẩn hóa 200.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; workbench state rỗng load health 200.
- Asset/provenance: none.
- Workbench chưa có player build recipe/unlock; package này không thay progression/economy. Resource depletion chưa persist.
- Rollback: revert workbench catalog/state/pending lifecycle, regression và docs U1.12t.

### Gói tiếp theo

U1.12u audit và persist riêng world resource depletion theo `NEXT_UPDATE_PROMPT.md`.
