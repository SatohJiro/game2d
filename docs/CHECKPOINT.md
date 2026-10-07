# Checkpoint triển khai Paloria 3.0

## U1.12x — raid-cycle guard persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Raid guard round-trip cùng clock để load giữa đêm không phát raid lặp.
- Guard true chỉ coherent từ phase 0.72; invalid/failed load không mutate world state.
- Không serialize/spawn raid actor; boss/spawn timers ngoài scope.

### Kết quả đã triển khai

- Thêm typed `WorldCycleState` và `world.cycle_state.raid_triggered_this_cycle`.
- Snapshot/apply/coordinator result handoff guard mà không giữ runtime Node/RNG/banner.
- Main `apply_world_cycle()` commit clock + guard sau load success, không gọi raid transaction.
- Save cũ thiếu cycle state mặc định guard false.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Editor-load, schema và coordinator regressions xanh: active-night clock 140 + guard true round-trip, không thêm raid creature.
- Guard true ở clock 45 fail schema; corrupt primary+backup giữ clock 44 + guard false.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save v1 pre-release thêm optional-compatible cycle state; API coordinator thêm bool mặc định false.
- Asset/provenance: none.
- Boss/spawn timers, autosave/UI và chunk persistence chưa phủ.
- Rollback: revert WorldCycleState/handoff/Main atomic apply, regressions và docs U1.12x.

### Gói tiếp theo

U1.12y persist riêng boss timer/guard theo `NEXT_UPDATE_PROMPT.md`.
