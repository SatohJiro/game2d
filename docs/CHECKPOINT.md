# Checkpoint triển khai Paloria 3.0

## U1.9u — burn tick combat boundary

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Xóa direct HP mutation của burn tick và route damage/defeat qua combat result boundary.
- Giữ cadence 0,8 giây, damage 8, capture pause, text/flash và killer compatibility.
- Không đổi status stacking/duration, skill catalog, drop, asset hoặc save.

### Kết quả đã triển khai

- `create_burn_tick_damage_request()` tạo snapshot với stable tags `status`, `burn`, `fire`.
- `resolve_burn_tick_damage()` commit qua `apply_damage_request`; presentation chỉ đọc `DamageResult`.
- Lethal tick đặt `defeat_committed` trước death side effects; duplicate tick bị chặn.

### Validation hiện tại

- Baseline full gate xanh.
- Focused combat regression xanh cho damage/tag/HP mutation và duplicate-defeat guard.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none. Asset/provenance: none.
- Status duration/stacking vẫn là state actor legacy; package này chỉ đóng damage writer.
- Rollback: revert U1.9u để khôi phục direct burn HP mutation; không cần migration.

### Gói tiếp theo

U1.10a audit roster/pet identity hiện tại và tạo `PetInstance` contract tối thiểu bằng stable ID, chưa thay summon/job gameplay. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
