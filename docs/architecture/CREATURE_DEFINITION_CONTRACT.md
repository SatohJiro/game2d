# U1.9a — CreatureDefinition canary contract

Trạng thái: `VERIFIED` ngày 2026-10-05.

Pure catalog: `data/definitions/creature_definition.gd`, `creature_behavior_profile.gd`
Canary: `data/definitions/creatures/flam.tres`
Compatibility boundary: `data/legacy_species_adapter.gd`, `scripts/creature.gd`

## Mục tiêu và invariant

- `creature.flam` là stable identity; index `0`, display name và texture path không phải identity.
- Mỗi field đã migrate chỉ có một authority. Runtime vẫn phát legacy-shaped snapshot để giữ consumer hiện hữu.
- Definition không chứa Node, runtime state hoặc localized display text làm khóa.
- Không đổi balance, asset, animation, collision, spawn, capture, skill hoặc drop outcome.

## Schema canary

`CreatureDefinition` kế thừa `ContentDefinition` và yêu cầu:

- `content_id` thuộc domain `creature`;
- `base_max_hp > 0`, `move_speed` dương/finite, `base_attack_power > 0`;
- một `CreatureBehaviorProfile` hợp lệ, không đồng thời predator và prey;
- `drop_item_id` thuộc domain `item` và tồn tại trong registry.

Flam giữ đúng prototype: 80 HP, speed 105, power 14, không predator/prey, drop `item.pal_ore`. Registry cross-reference bảo đảm drop tồn tại.

## Field/consumer audit

| Legacy source | Consumer chính | U1.9a owner |
|---|---|---|
| `species_index` | spawn/main/altar, pack equality, attack dispatch | Compatibility selector qua `LegacySpeciesAdapter`; chưa phải persistent identity |
| `name`, `element`, `texture` | overhead, pet/UI, presentation | Legacy presentation row giữ nguyên |
| `max_hp`, `speed`, `power` | creature/pet combat và locomotion snapshot | `CreatureDefinition` cho Flam |
| `is_predator`, `is_prey` | ecology/natural behavior | Embedded `CreatureBehaviorProfile` cho Flam |
| `drop_item` | defeated creature drop | `drop_item_id` typed; adapter ánh xạ về legacy item key |

Trước package, row Flam chứa sáu field gameplay `max_hp/speed/power/is_predator/is_prey/drop_item`. Sau package cả sáu bị xóa khỏi row; `create_runtime_snapshot()` chiếu chúng từ definition. Ba field presentation còn lại không bị nhân đôi trong typed canary.

## Validation và compatibility

- Definition validator reject wrong domain, stat invalid, thiếu/conflict behavior và wrong-domain drop.
- Registry reject missing `drop_item_id` và load tổng cộng 11 definitions.
- Actor regression xác nhận Flam runtime vẫn nhận stable ID, stats và legacy drop key đúng; row legacy không còn `max_hp`.
- Các species khác vẫn dùng dictionary authority qua cùng adapter và không đổi behavior.

Save/data breaking change: none; chưa có save schema và snapshot party hiện giữ format legacy kèm stable species ID. Asset/provenance: none; texture hiện hữu vẫn quarantine/unknown. Rollback: revert U1.9a, không cần migration.

## Boundary tiếp theo

U1.9b audit species attack/charge và tạo typed skill reference/definition canary. Không migrate ecology/drop resolution trong cùng package.

## U1.9k — Slime typed definition

`creature.slime` nay là typed authority cho 110 HP, speed 85, power 9, prey=true/predator=false và drop reference `item.berry`. Sáu field gameplay tương ứng đã được xóa khỏi legacy Slime row; name, element và texture vẫn là presentation compatibility data.

`LegacySpeciesAdapter` resolve Flam/Slime definition theo stable ID rồi chiếu về snapshot shape cũ. Slime hop vẫn dùng species branch và `primary_skill_definition == null`; defeat drop execution vẫn dùng legacy path nhưng stable drop mapping giữ nguyên outcome Quả Mọng. Tại mốc U1.9k, Mushroom/Beast/Dragon tiếp tục fallback sang legacy dictionary; invalid index fail closed.

Registry hiện có 13 definitions. Regression khóa catalog reference, stat parity, prey role, legacy display/drop compatibility, Mushroom fallback và invalid snapshot. Save/data breaking change: none; asset/provenance: none.

## U1.9l — Mushroom typed definition

`creature.mushroom` nay là typed authority cho 90 HP, speed 95, power 11, prey=true/predator=false và drop reference `item.berry_seed`. Sáu field gameplay đã được xóa khỏi legacy Mushroom row; name, element và texture vẫn là presentation compatibility data.

Adapter chiếu definition về snapshot shape cũ và dùng mapping `item.berry_seed` ↔ `Hạt Giống Cây`, nên storage/display và drop outcome không đổi. Mushroom spore vẫn chạy species branch với `primary_skill_definition == null`; Beast/Dragon tiếp tục legacy fallback. Registry hiện có 14 definitions; regression khóa stat/role/drop parity, empty typed skill list và Beast fallback.

## U1.9m — Beast typed definition

`creature.beast` nay là typed authority cho 130 HP, speed 115, power 16, predator=true/prey=false và drop reference `item.fresh_meat`. Sáu field gameplay đã được xóa khỏi legacy Beast row; name, element và texture vẫn là presentation compatibility data.

Adapter chiếu definition về snapshot shape cũ và dùng mapping `item.fresh_meat` ↔ `Thịt Tươi`, nên inventory/cooking/ranch key và drop outcome không đổi. Beast charge vẫn chạy species branch với `primary_skill_definition == null`; Dragon tiếp tục legacy fallback. Registry có 16 definitions gồm item reference mới; regression khóa stat/role/drop parity, empty typed skill list và Dragon fallback. Save/data breaking change: none; `beaf.png` vẫn là baseline quarantine asset, không được admit lại.
