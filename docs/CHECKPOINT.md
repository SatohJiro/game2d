# Checkpoint triển khai Paloria 3.0

## U1.12y — boss timer/guard persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Boss pre-spawn timer/guard round-trip cùng typed world cycle.
- Spawned boss bắt buộc timer 0; pre-spawn timer trong `(0,50]`.
- Load không gọi spawn boss; actor/HP và ambient spawn timer ngoài scope.

### Kết quả đã triển khai

- Mở rộng `WorldCycleState` bằng `boss_spawned` và `boss_timer`.
- Snapshot/apply/coordinator handoff boss scalars cùng clock/raid guard.
- Main commit atomically sau load success, không gọi `spawn_boss()`.
- Cycle DTO một-field cũ mặc định boss chưa spawn/timer 50.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Editor-load, schema và coordinator regressions xanh: boss timer 23.5 round-trip, không thêm boss actor.
- Spawned+timer 4 bị reject; corrupt save giữ runtime boss timer 12.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save v1 pre-release mở rộng cycle state; one-field DTO cũ tương thích.
- Asset/provenance: none.
- Boss actor HP, ambient spawn timer, autosave/UI và chunk persistence chưa phủ.
- Rollback: revert boss fields/handoff/Main apply, regressions và docs U1.12y.

### Gói tiếp theo

U1.12z persist riêng ambient spawn timer theo `NEXT_UPDATE_PROMPT.md`.
