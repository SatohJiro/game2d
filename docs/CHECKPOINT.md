# Checkpoint triển khai Paloria 3.0

## U1.9l — Mushroom typed definition

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Dùng stable `creature.mushroom` làm typed authority cho stats/behavior Mushroom.
- Giữ species index, name/element/texture, spore skill, Hạt Giống drop và ecology behavior hiện hữu.
- Không migrate Beast/Dragon, Mushroom spore/drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm `data/definitions/creatures/mushroom.tres`: 90 HP, speed 95, power 11, prey role và `item.berry_seed` drop reference.
- Xóa sáu field gameplay khỏi legacy Mushroom row; ba field presentation vẫn giữ nguyên.
- `LegacySpeciesAdapter` resolve typed Flam/Slime/Mushroom definitions; Beast/Dragon tiếp tục legacy fallback.
- Bổ sung mapping hai chiều `item.berry_seed` ↔ `Hạt Giống Cây`; inventory storage chưa migrate.
- Mushroom vẫn không có typed primary skill và spore/drop execution không đổi.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Content validator xanh với 14 definitions, Mushroom stat/behavior/drop reference và empty skill list.
- Actor regression xanh cho stable ID, stat parity, prey role, legacy seed key, spore path và Beast fallback.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset integrity, content/domain validators, editor load và main-scene smoke đều đạt; log không còn script/parse/missing dependency/invalid node error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; stable species ID, inventory key và runtime snapshot shape không đổi.
- Asset/provenance: không thêm/sửa asset; Mushroom texture hiện hữu vẫn quarantine/unknown.
- Mushroom spore/drop execution cùng Beast/Dragon catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9l; không cần migration.

### Gói tiếp theo

U1.9m mở rộng typed `CreatureDefinition` cho riêng Beast, giữ charge/drop/ecology compatibility. Không migrate Dragon hay skill/drop execution cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
