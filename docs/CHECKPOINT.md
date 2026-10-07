# Checkpoint triển khai Paloria 3.0

## U1.12ac — world-boss Save v1 admission

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- World-boss lifecycle/HP/position round-trip qua Save v1 và Main boundary.
- Active restore đúng một actor; pending/defeated không spawn; restore không phát presentation/reward.
- Invalid/corrupt load phải dừng trước world mutation và giữ actor/state runtime.

### Kết quả đã triển khai

- Schema thêm `world.world_boss_state` và khóa coherence với cycle boss guard.
- Snapshot project live actor HP/position; apply/coordinator handoff typed copy tới Main.
- Main thay actor cũ rồi restore active qua `spawn_boss(false)` hoặc giữ pending/defeated không actor.
- Save cũ thiếu field suy ra pending khi chưa spawn và defeated khi đã spawn để tránh reward/respawn lặp.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused schema/coordinator regressions xanh: JSON/coherence/legacy fallback, active HP 217 + position round-trip, defeated no-spawn, corrupt preserve.
- Active restore giữ đúng một actor và không tăng EXP/drop.
- Full `tools/check_project.ps1` xanh: 42 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save/world-boss validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save v1 pre-release mở rộng optional world boss field; missing-field compatibility không cần version bump.
- Asset/provenance: none.
- Capture/despawn ngoài defeat, raid actor và chunk persistence chưa phủ.
- Rollback: revert world-boss DTO/handoff/Main apply, regressions và docs U1.12ac.

### Gói tiếp theo

U1.12ad đóng world-boss capture lifecycle theo `NEXT_UPDATE_PROMPT.md`.
