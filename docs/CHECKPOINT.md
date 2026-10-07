# Checkpoint triển khai Paloria 3.0

## U1.12l — typed altar boss lifecycle persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Active altar save/load giữ stable boss identity và HP, luôn đúng một boss actor.
- Restore không thu offering, không phát summon/completion banner và không serialize Node.
- Invalid lifecycle/identity/HP fail trước mutation; combat/cost/reward giữ nguyên.

### Kết quả đã triển khai

- Thêm `AltarPlacementState` với idle/active, `boss.instance_*` và HP 1–280.
- Altar restore spawn actor sau add-tree và áp HP sau `Creature._ready()`.
- Player dọn boss cũ bằng suppression marker trước khi thay placement, tránh callback completion giả.
- Snapshot đọc HP live qua runtime reference nhưng DTO chỉ chứa scalar/ID.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và focused `validate_save_schema.gd` xanh.
- Regression apply/snapshot/apply giữ đúng một boss ID với 137 HP; idle stale state và HP 281 bị reject.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; altar record cũ thiếu state load idle.
- Asset/provenance: none.
- Turret, building health và resource depletion chưa persist.
- Rollback: revert altar state, altar/Player lifecycle bridge, regression và docs U1.12l.

### Gói tiếp theo

U1.12m persist riêng turret mutable state theo `NEXT_UPDATE_PROMPT.md`.
