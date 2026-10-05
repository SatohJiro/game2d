# Checkpoint triển khai Paloria 3.0

## U1.9m — Beast typed definition

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Dùng stable `creature.beast` làm typed authority cho stats/behavior Beast.
- Giữ species index, name/element/texture, charge attack, Thịt Tươi drop và predator ecology hiện hữu.
- Không migrate Dragon, Beast charge/drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm `data/definitions/creatures/beast.tres`: 130 HP, speed 115, power 16, predator role và `item.fresh_meat` drop reference.
- Thêm `item.fresh_meat` definition cùng mapping hai chiều `Thịt Tươi`; legacy inventory/cooking/ranch key không đổi.
- Xóa sáu field gameplay khỏi legacy Beast row; ba field presentation vẫn giữ nguyên.
- `LegacySpeciesAdapter` resolve typed Flam/Slime/Mushroom/Beast definitions; Dragon tiếp tục legacy fallback.
- Beast vẫn không có typed primary skill và charge/drop execution không đổi.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused content validator xanh với 16 definitions, Beast stat/behavior/drop reference và empty skill list.
- Focused actor regression xanh cho stable ID, stat parity, predator role, legacy fresh-meat key, charge path và Dragon fallback.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset integrity, content/domain validators, editor load và main-scene smoke đều đạt; log không còn script/parse/missing dependency/invalid node error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; stable species ID, inventory key và runtime snapshot shape không đổi.
- Asset/provenance: không thêm/sửa asset; `beaf.png` và Beast texture hiện hữu vẫn `QUARANTINE/UNKNOWN`.
- Beast charge/drop execution cùng Dragon catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9m; không cần migration.

### Gói tiếp theo

U1.9n mở rộng typed `CreatureDefinition` cho riêng Dragon, giữ melee/fireball/drop compatibility. Không migrate Dragon skill/drop execution cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
