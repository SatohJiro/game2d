# Checkpoint triển khai Paloria 3.0

## U1.12p — cooking-pot durability foundation and persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Cooking pot có durability runtime rõ ràng và save/load giữ recipe/progress/health trong cùng typed state.
- Restore không gọi cooking tick, finish/reward, damage, destruction hay presentation path.
- Health ngoài 1–200 fail trước mutation; recipe timer/cost/reward giữ nguyên.

### Kết quả đã triển khai

- Audit xác nhận cooking pot trước U1.12p không có health/max-health/damage rule.
- Thêm foundation 200 HP theo workbench, `buildings` group và damage/destruction pattern hiện có.
- Mở rộng `CookingPotPlacementState`; state recipe/progress cũ mặc định 200 HP và pending restore sống qua `_ready()`.
- Regression giữ hearty stew, timer 1.75 và 121 HP; health 201 giữ runtime cũ.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh; chỉ còn cảnh báo môi trường CA/log `user://` đã biết.
- Regression apply/snapshot/apply giữ recipe/progress + 121 health; health 201 bị reject trước runtime replacement.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; cooking state hai field cũ load health 200.
- Asset/provenance: none.
- Max health 200 là balance assumption mới, căn theo workbench; chưa chuyển sang typed BuildingDefinition.
- Health của ranch/altar/turret/workbench chưa persist; compost/farm plot chưa có durability runtime; resource depletion chưa persist.
- Rollback: revert cooking-pot durability foundation/state field, regression và docs U1.12p.

### Gói tiếp theo

U1.12q persist riêng ranch durability theo `NEXT_UPDATE_PROMPT.md`.
