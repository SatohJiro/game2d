# Checkpoint triển khai Paloria 3.0

## U1.12aa — world-boss actor audit và typed contract

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Audit lifecycle world boss trước khi admit HP/position vào Save v1.
- Stable identity/lifecycle phải phân biệt pending, active và defeated.
- Không serialize Node/scene/banner/RNG và không restore actor khi ownership/defeat callback chưa an toàn.

### Kết quả đã triển khai

- Thêm pure `WorldBossState` với fixed ID `boss.world_dragon_1`, max HP 380 và finite position.
- Lifecycle pending/active/defeated có canonical invariant và exact-shape DTO.
- Audit xác nhận Main chưa giữ actor reference; `boss_spawned` không phân biệt active/defeated; Creature chưa signal defeat.
- Save v1/runtime không đổi; contract được giữ sau admission gate.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Baseline full gate xanh trước thay đổi.
- Focused regression xanh: active HP/position JSON round-trip; unstable ID, HP 0/fraction và invalid defeated state bị reject.
- Full `tools/check_project.ps1` xanh: 42 Markdown files, asset/content gates, editor load, toàn bộ gameplay/save validators và world-boss state validator; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; state mới chưa được nối Save v1.
- Asset/provenance: none.
- Boss actor ownership, defeat signal, restore/reward suppression và chunk persistence chưa phủ.
- Rollback: xóa `WorldBossState`, validator/gate và docs U1.12aa.

### Gói tiếp theo

U1.12ab thiết lập world-boss actor ownership/defeat signal theo `NEXT_UPDATE_PROMPT.md`.
