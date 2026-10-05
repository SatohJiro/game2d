# Checkpoint triển khai Paloria 3.0

## U1.9n — Dragon typed definition

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Dùng stable `creature.dragon` làm typed authority cho stats/behavior Dragon.
- Giữ species index, name/element/texture, forced-elite scaling, melee/fireball, Thỏi Pal drop và predator ecology hiện hữu.
- Không migrate Dragon skill/drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm `data/definitions/creatures/dragon.tres`: 340 HP, speed 95, power 26, predator role và `item.pal_ingot` drop reference.
- Thêm `item.pal_ingot` definition cùng mapping hai chiều `Thỏi Pal`; legacy inventory/furnace/altar/progression key không đổi.
- Xóa sáu field gameplay khỏi legacy Dragon row; ba field presentation vẫn giữ nguyên.
- `LegacySpeciesAdapter` resolve typed definitions cho đủ năm species.
- Dragon vẫn luôn elite, không có typed primary skill và melee/fireball/drop execution không đổi.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused content validator xanh với 18 definitions, Dragon stat/behavior/drop reference và empty skill list.
- Focused actor regression xanh cho stable ID, base stat parity, forced-elite scaling, predator role, legacy Pal-ingot key và invalid index.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset integrity, content/domain validators, editor load và main-scene smoke đều đạt; log không còn script/parse/missing dependency/invalid node error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; stable species ID, inventory key và runtime snapshot shape không đổi.
- Asset/provenance: không thêm/sửa asset; `pal_ingot.png` và Dragon texture hiện hữu vẫn `QUARANTINE/UNKNOWN`.
- Dragon melee/fireball/drop execution cùng remaining species skill/drop catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9n; không cần migration.

### Gói tiếp theo

U1.9o migrate riêng Dragon fireball sang typed skill definition, giữ melee selection, timing, damage và lifecycle compatibility. Không migrate các species skill/drop khác cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
