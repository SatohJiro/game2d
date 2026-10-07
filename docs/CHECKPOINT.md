# Checkpoint triển khai Paloria 3.0

## U1.12z — ambient spawn timer persistence

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Ambient spawn countdown round-trip cùng typed world cycle.
- Timer hợp lệ trong `(0,4]`; DTO cycle cũ mặc định initial timer 3 giây.
- Load chỉ commit scalar, không gọi creature maintenance và không serialize roster/species/offset/RNG.

### Kết quả đã triển khai

- Mở rộng `WorldCycleState` bằng `spawn_timer` và validation hữu hạn theo interval.
- Snapshot/apply/coordinator handoff timer cùng clock, raid guard và boss state.
- Main commit timer atomically sau load success, không gọi `maintain_creatures()`.
- Cycle DTO một/ba-field cũ vẫn parse và nhận initial timer 3 giây.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Editor-load, schema và coordinator regressions xanh: timer 2.25 round-trip và creature count không đổi khi load.
- Timer 4.1 bị reject trước mutation; corrupt save giữ runtime timer 1.5.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save v1 pre-release mở rộng cycle state; one/three-field DTO cũ tương thích.
- Asset/provenance: none.
- Boss actor HP, creature roster, autosave/UI và chunk persistence chưa phủ.
- Rollback: revert ambient timer field/handoff/Main apply, regressions và docs U1.12z.

### Gói tiếp theo

U1.12aa audit world-boss actor lifecycle theo `NEXT_UPDATE_PROMPT.md`.
