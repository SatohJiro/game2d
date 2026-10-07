# Checkpoint triển khai Paloria 3.0

## U1.12r — altar structure durability persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Altar save/load giữ structure health độc lập với boss identity/HP trong cùng typed state.
- Restore đúng một boss nhưng không gọi offering, summon/completion, reward hay destruction flow.
- Altar health ngoài 1–1000 fail trước mutation; boss lifecycle/HP và max health giữ nguyên.

### Kết quả đã triển khai

- Mở rộng `AltarPlacementState` bằng `altar_health` 1–1000, tách khỏi `boss_hp` 1–280.
- Lifecycle DTO ba field cũ mặc định altar health 1000; pending health sống qua `_ready()`.
- Boss replacement tiếp tục dùng suppression guard nên không phát completion giả.
- Regression giữ altar 641 HP và đúng một boss ID với 137 HP; altar health 1001 giữ runtime cũ.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh; chỉ còn cảnh báo môi trường CA/log `user://` đã biết.
- Regression apply/snapshot/apply giữ altar/boss state riêng biệt; health 1001 bị reject trước runtime replacement.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; altar lifecycle ba field cũ load structure health 1000.
- Asset/provenance: none.
- Altar chưa có `take_damage()`; package chỉ persist mutable health hiện hữu, không thêm damage rule.
- Health của turret/workbench chưa persist; compost/farm plot chưa có durability runtime; resource depletion chưa persist.
- Rollback: revert altar structure health/pending lifecycle, regression và docs U1.12r.

### Gói tiếp theo

U1.12s persist riêng turret structure durability theo `NEXT_UPDATE_PROMPT.md`.
