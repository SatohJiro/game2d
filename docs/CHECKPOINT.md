# Checkpoint triển khai Paloria 3.0

## U1.9k — Slime typed definition

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Dùng stable `creature.slime` làm typed authority cho stats/behavior Slime.
- Giữ species index, name/element/texture, hop skill, drop outcome và ecology behavior hiện hữu.
- Không migrate Mushroom/Beast/Dragon, Slime hop/drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm `data/definitions/creatures/slime.tres`: 110 HP, speed 85, power 9, prey role và `item.berry` drop reference.
- Xóa sáu field gameplay khỏi legacy Slime row; ba field presentation vẫn giữ nguyên.
- `LegacySpeciesAdapter` resolve typed Flam/Slime definition theo stable ID và chiếu về legacy-shaped runtime snapshot.
- Slime vẫn không có typed primary skill; Mushroom/Beast/Dragon tiếp tục legacy fallback; invalid index fail closed.
- Creature validator teardown được làm deterministic sau khi thêm actor fixture thứ hai.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Content validator xanh với 13 definitions, Slime stat/behavior/drop reference và empty skill list.
- Actor regression xanh cho stable ID, stat parity, prey role, legacy drop key, hop path, Mushroom fallback và invalid snapshot.
- Creature validator chạy sạch leak hai lần liên tiếp.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, content/actor regressions và main smoke.
- Final content/creature logs sạch ObjectDB/resource leak.
- `git diff --check` và final log scan được yêu cầu sạch trước commit.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; stable species ID và runtime snapshot shape không đổi.
- Asset/provenance: không thêm/sửa asset; Slime texture hiện hữu vẫn quarantine/unknown.
- Slime hop/drop execution cùng Mushroom/Beast/Dragon catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9k; không cần migration.

### Gói tiếp theo

U1.9l mở rộng typed `CreatureDefinition` cho riêng Mushroom, giữ spore skill/drop/ecology compatibility. Không migrate Beast/Dragon hay skill/drop execution cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
