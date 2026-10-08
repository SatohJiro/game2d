# Content ID, definition và registry contract

## Mục tiêu

Gameplay và save tham chiếu content bằng ID ổn định; text hiển thị, scene path và asset path có thể đổi mà không phá state. U1.1 tạo nền móng và canary `item.wood`; U1.2 đã nối stable ID vào luồng pickup gỗ trong khi dictionary runtime vẫn dùng key legacy `Gỗ` làm nguồn sự thật duy nhất.

## Content ID

Grammar bắt buộc:

```text
^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$
```

- Ít nhất hai segment: `<domain>.<local_name>`.
- Chỉ lowercase ASCII, số và `_`; mỗi segment bắt đầu bằng chữ.
- ID là identity vĩnh viễn. Không đổi ID để sửa tên hiển thị hoặc cân bằng.
- Subtype/version có thể thêm segment: `creature.foxfire.elite`; không đưa level hoặc instance UUID vào content ID.

Domain đã dành trước:

| Domain | Definition owner | Ví dụ |
|---|---|---|
| `item` | ItemDefinition | `item.wood` |
| `creature` | CreatureDefinition | `creature.foxfire` |
| `skill` | SkillDefinition | `skill.fire_bolt` |
| `recipe` | RecipeDefinition | `recipe.sphere.basic` |
| `building` | BuildingDefinition | `building.workbench` |
| `crop` | CropDefinition | `crop.berry` |
| `biome` | BiomeDefinition | `biome.starter_meadow` |
| `quest` | QuestDefinition | `quest.base.first_capture` |

U1.12ai dành namespace `equipment.weapon.*` và `equipment.armor.*` cho gear Player. Đây là allowlist persistence trong `PlayerEquipmentCatalog`, chưa phải registry definition: weapon gồm wood sword/iron sword/Pal blade; armor gồm none/Pal warrior. Localized name, crafting short ID, asset path và damage/bonus derived không được dùng làm identity.

Runtime capture sphere IDs đã được admit ở U1.7b: `item.pal_sphere.basic`, `item.pal_sphere.mega`, `item.pal_sphere.giga`. Cả ba map vào backing dictionary legacy qua `LegacyItemAdapter`; stable ID là identity cho selection/projectile/drop, text cũ chỉ là compatibility storage/display.

U1.7c dành năm stable species ID `creature.flam`, `creature.slime`, `creature.mushroom`, `creature.beast`, `creature.dragon`. `LegacySpeciesAdapter` map index hiện hữu sang ID và deep-copy snapshot tại capture boundary. Đây là compatibility mapping; chưa có typed `CreatureDefinition` hoặc registry entry.

U1.9a và U1.9k–n đã admit typed definitions cho toàn bộ năm species `creature.flam`, `creature.slime`, `creature.mushroom`, `creature.beast` và `creature.dragon`. Stable IDs không đổi; adapter chiếu stats/behavior/drop reference sang legacy-shaped runtime snapshot, còn localized name/element/texture vẫn là presentation data legacy.

U1.10a dùng domain `pet` cho identity cá thể sở hữu (`pet.instance_*`). `creature.*` vẫn là species identity; pet instance ID không phải definition registry key và không được suy ra từ display text, party index hoặc Node instance ID.

U1.10c–d dùng namespace `pet.command.*` và `pet.stance.*` cho runtime intent/state identity, gồm cycle cùng explicit auto-work/combat-assist/follow-protect. Đây chưa phải catalog definition hay save DTO; localized HUD text và enum số không được dùng thay các ID này tại boundary.

U1.12c dành `pet.rarity.*` và `pet.trait.*` làm identity bền vững cho bốn rarity và bảy trait hiện hữu. `PetMetadataCatalog` là allowlist + projection sang badge/name legacy; Save v1 chỉ ghi ID. `pet.stance.*` được lưu trên từng roster entry, không suy ra pet inactive từ Node hay enum.

U1.12d admit năm identity `quest.base.*` trong `BaseQuestCatalog`. Localized title, reward text và array index chỉ là compatibility/content ordering; Save v1 dùng `active_quest_id` cùng `claimed_quest_ids`. `BaseProgressState` validate prefix/order/base-level coherence trước snapshot hoặc apply.

U1.12e admit stable subtype cho chín placement reachable và instance namespace `building.instance_*`. `BuildingPlacementCatalog` là compatibility map/factory; scene path không được serialize hoặc dùng làm identity. `BuildingPlacementRecord` validate subtype và transform trước Save apply.

U1.12f admit `ChestPlacementState` cho đúng `building.chest`. Inventory DTO dùng stable item ID thay vì localized legacy key; item ngoài contract chest và state gắn lên subtype khác đều bị reject.

U1.12g admit `FurnacePlacementState` cho đúng `building.furnace`. Các count và timer là scalar JSON-safe; active/boost presentation không trở thành identity hoặc persisted authority.

U1.12h admit năm stable recipe ID `recipe.cooking.smoked_meat`, `hearty_stew`, `purified_water`, `berry_jam`, `golden_wheat_bread`. `CookingRecipeCatalog` là compatibility map tới row runtime hiện hữu; localized dish name và legacy short ID không được dùng trong save.

U1.13b admit 17 Player craft ID dưới `recipe.item.*`, `recipe.equipment.*` và `recipe.building.*` qua typed `PlayerCraftDefinition`. Input/result chỉ dùng stable domain ID; localized name, success text và asset path là presentation. Legacy short recipe ID chỉ được resolve tại compatibility boundary, HUD mới phát stable ID.

U2.1 thêm domain `biome.*` và `chunk.*`. `chunk.<name>` là content definition ID; runtime coordinate key dùng canonical `chunk.pN.nN`, không thay thế definition ID và không dùng raw dấu trừ. Chi tiết tại `WORLD_CHUNK_CONTRACT.md`.

U1.12i admit `CompostBinPlacementState` cho đúng `building.compost_bin`. State chỉ chứa scalar JSON-safe với range/coherence validation; fertilizer display text không trở thành identity.

U1.12j admit ranch assignment identity: owned pet giữ `pet.instance_*`; resident baseline dùng `ranch.resident_starter` trong scope của building record. Save giữ stable species ID, không giữ localized species name hoặc runtime animal Node.

U1.12k admit typed `crop.golden_wheat` và `crop.pal_herb`, cùng `crop.berry` tạo allowlist persistence cho farm plot. Stage dùng `farm.stage.empty|seeded|growing|ready`; enum số và localized crop name không đi vào save.

U1.12l dành `altar.lifecycle.*` cho state và `boss.instance_*` cho encounter instance identity. Boss Node, scene path và banner text không phải persistence identity.

U1.12m turret persistence không thêm identity mới: state chỉ có scalar `cooldown_remaining`. Target Node, projectile, Callable và scene/asset path không được dùng làm identity hoặc đưa qua DTO.

U1.12n chest durability không thêm identity mới: `health` là scalar state, còn `max_health = 250` là contract/tuning hiện tại. Node, scene path, tween và destruction callback không đi qua DTO.

U1.12o furnace durability không thêm identity mới: `health` là scalar state, `max_health = 300` là tuning hiện tại. Node, scene path, pet boost, tween và smelting callback không đi qua DTO.

U1.12p cooking-pot durability không thêm identity mới: `health` là scalar state và max health 200 là tuning foundation mới, tạm căn theo workbench. Node, scene path, player-in-range, tween và finish callback không đi qua DTO.

U1.12q ranch durability không thêm identity mới: `health` là scalar state, max health 350 giữ nguyên. Animal/presentation Node, scene path, tween và production callback không đi qua DTO.

U1.12r altar dùng hai scalar phân biệt: `altar_health` cho structure và `boss_hp` cho encounter actor; không field nào là identity. Stable `boss.instance_*` vẫn là encounter identity duy nhất; altar/boss Node và scene path không đi qua DTO.

U1.12s turret state chỉ có cooldown/health scalar và không thêm identity. Target/projectile Node, Callable, scene path, tween và fire callback không đi qua DTO.

U1.12t admit `building.workbench` vào placement persistence catalog nhưng không mở recipe/unlock xây mới. `WorkbenchPlacementState` chỉ giữ scalar `health` trong miền 1–200; record state rỗng được chuẩn hóa thành 200 để tương thích. Player, HUD, crafting callback, Node, Callable và scene/asset path không đi qua DTO.

U1.12u dành `resource.tree` cho subtype và `resource.tree_*` cho sáu instance tĩnh trong main scene. `ResourceDepletionRecord` chỉ giữ hai scalar coherent: tree sống có health 1–60/timer 0; tree depleted có health 0/timer `(0,18]`. Enum `NodeType`, localized drop name, Node và scene/asset path không đi qua DTO. Save v1 cũ thiếu `world.resource_deltas` được hiểu là mảng rỗng.

U1.12v mở cùng contract cho `resource.rock` và bốn instance `resource.rock_1`…`resource.rock_4`. Max health do stable subtype quyết định: tree 60, rock 80; max health không serialize. Random rock texture chỉ là presentation và không trở thành identity/state. Cả hai subtype dùng respawn countdown 18 giây deterministic.

U1.12ae dành `raid.night_current` cho encounter hiện tại, `raid.night_actor_1..3` cho ba slot actor và `raid.lifecycle.*` cho lifecycle. Actor state lưu resolved `creature.*`, không lưu species/angle/radius RNG; cycle index kết hợp encounter ID để phân biệt các đêm lặp lại.

U1.11a dành domain `save` cho envelope identity (`save.slot_1`) và bắt đầu Save v1 dùng String stable IDs trong JSON DTO. Schema/validation đầy đủ ở `SAVE_CONTRACT.md`; StringName runtime phải project thành String, không serialize object trực tiếp.

U1.11b admit `item.stone` và `item.iron_ingot`, map hai chiều với `Đá`/`Thỏi Sắt`, để inventory mặc định có thể snapshot không mất dữ liệu. Hai definitions dùng icon baseline hiện hữu; provenance vẫn `QUARANTINE/UNKNOWN`, không có asset mới.

U1.12b admit 14 identity còn thiếu cho fertilizer, stamina elixir, herb/wheat seed và harvest, ranch material cùng năm món ăn: `item.fertilizer.organic_pal`, `item.fertilizer.pal`, `item.elixir.stamina`, `item.pal_herb`, `item.slime_essence`, `item.golden_wheat`, `item.pal_herb_seed`, `item.golden_wheat_seed`, `item.flame_organ` và `item.food.*`. `RuntimeInventoryManifest` khóa 25 localized key reachable theo nhóm core/crafting/farming/ranch/cooking; validator bắt buộc mapping hai chiều và typed `ItemDefinition`. Toàn bộ icon chỉ tái sử dụng baseline, vẫn `QUARANTINE/UNKNOWN`; không admit asset mới và backing dictionary chưa migrate.

U1.9l nối mapping hai chiều `item.berry_seed` ↔ `Hạt Giống Cây` trong `LegacyItemAdapter` để typed Mushroom drop reference giữ đúng storage/display key hiện hữu. Đây là compatibility mapping; inventory storage chưa migrate.

U1.9m admit `item.fresh_meat` và mapping hai chiều `item.fresh_meat` ↔ `Thịt Tươi` để typed Beast drop reference giữ nguyên storage/display và cooking/ranch compatibility. Asset `beaf.png` chỉ được tham chiếu lại từ baseline, vẫn `QUARANTINE/UNKNOWN`; inventory storage chưa migrate.

U1.9n admit `item.pal_ingot` và mapping hai chiều `item.pal_ingot` ↔ `Thỏi Pal` để typed Dragon drop reference giữ nguyên storage, furnace/altar/progression và display compatibility. Asset `pal_ingot.png` chỉ được tham chiếu lại từ baseline, vẫn `QUARANTINE/UNKNOWN`; inventory storage chưa migrate.

U1.9o admit `skill.dragon.fireball` làm balance identity riêng và reference duy nhất của `creature.dragon`. Giá trị hiện giữ parity với Flam fireball nhưng hai species không chia sẻ ID/authority; melee selection và presentation vẫn thuộc actor adapter.

U1.9p admit `skill.mushroom.spore` làm typed projectile authority của `creature.mushroom`; kiting/escape và presentation vẫn thuộc actor adapter.

U1.9q admit `skill.slime.hop` bằng subtype `HopSkillDefinition`, sở hữu cooldown, hop velocity/height và bốn nhịp squash/stretch; actor chỉ thực thi tween/movement.

U1.9r admit `skill.beast.charge` bằng `ChargeSkillDefinition`, sở hữu range, telegraph/cooldown, charge speed/duration và stun recovery; actor FSM vẫn sở hữu transition/contact/wall response.

U1.9s admit `skill.beast.melee` và `skill.dragon.melee` bằng `MeleeSkillDefinition`; identity tách riêng dù phần lớn tuning hiện giống nhau, với activation range 38/48px.

`ContentId` tại `core/content_id.gd` là API duy nhất để validate, tạo và tách domain/local name. Không tự ghép hoặc parse ID trong gameplay system.

## Definition contract

`ContentDefinition` là base Resource:

- `content_id: StringName`: identity ổn định và duy nhất toàn registry.
- `display_name_key: StringName`: localization key, không phải text hiển thị.
- `developer_notes: String`: ghi chú editor, không tham gia gameplay/save.
- `get_validation_errors()`: trả mọi lỗi có thể phát hiện, không sửa data âm thầm.

`ItemDefinition` mở rộng:

- ID phải thuộc domain `item`.
- `max_stack > 0`.
- `icon` bắt buộc resolve được.
- `tags` dùng để query/capability; không dùng text UI làm tag.

Definition đặt dưới `res://data/definitions/**` dưới dạng `.tres`/`.res`. Mọi resource trong cây này phải kế thừa `ContentDefinition`; file helper/script không bị registry coi là definition.

U1.3 thêm `ItemAmount`, `RecipeDefinition`, `BuildingDefinition` và `CropDefinition`. Schema, range, cross-reference và ranh giới runtime được ghi tại `DOMAIN_DEFINITIONS.md`.

## Registry contract

`ContentRegistry.load_directory(root)`:

1. Clear state cũ.
2. Thu thập `.tres`/`.res` đệ quy và sort path để validation deterministic.
3. Load, kiểm tra type và gọi validation của definition.
4. Reject duplicate ID; definition đầu tiên theo path sort được giữ, duplicate không ghi đè.
5. Sau khi register toàn catalog, validate reference theo stable ID đã sort; missing target là lỗi.
6. Trả `false` nếu có bất kỳ lỗi; caller đọc toàn bộ `get_errors()`.

Public query hiện có: `has`, `get_definition`, `get_definitions_for_domain`, `get_all_ids`, `size`. `validate_references` phục vụ catalog dựng thủ công/test sau khi register xong. Registry trả Resource definition; domain system cast về subtype và không mutate definition runtime.

U1.1 chưa autoload registry. Bootstrap/service lifetime chỉ được chốt khi một runtime consumer được migrate, tránh tạo global singleton trước khi ownership rõ.

## Canary và legacy mapping

| Legacy runtime key | Stable ID | Definition | Runtime migrated |
|---|---|---|---|
| `Gỗ` | `item.wood` | `data/definitions/items/wood.tres` | Pickup/player boundary; storage còn legacy |

Canary dùng asset `assets/items/wood.png`, hiện vẫn `QUARANTINE/UNKNOWN`. Definition không thay đổi license status của asset.

`LegacyItemAdapter` cho phép đọc/ghi gỗ bằng `item.wood` nhưng chỉ mutate `inventory["Gỗ"]`. Chi tiết data flow, API và failure policy nằm trong `INVENTORY_MIGRATION.md`. Không mở rộng mapping bằng text tùy ý: mỗi mapping cần definition và regression. Khi save v1 xuất hiện, save chỉ ghi stable ID. Mapping legacy phải tồn tại trong migration cho tới khi không còn save/data cũ cần hỗ trợ.

## Localization

`display_name_key` dạng `<content_id>.name`, ví dụ `item.wood.name`. UI resolve key qua localization service sau này. Definition không lưu trực tiếp `Gỗ`, `Wood` hoặc text ngôn ngữ khác làm identity.

## Thêm definition mới

1. Chọn domain và ID theo grammar; search toàn project để tránh semantic duplicate.
2. Tạo subtype đúng domain và `.tres` dưới `data/definitions/<domain>/`.
3. Ghi localization key, typed fields và asset đã có manifest/action.
4. Thêm validation subtype cho required field, range và cross-reference.
5. Chạy `tools/check_project.ps1`; content validation phải xanh.
6. Cập nhật module/feature/checkpoint và save migration nếu ID đã đi vào persistent state.

## Failure policy

- Invalid/duplicate/missing definition làm content gate exit khác 0.
- Runtime consumer không được tự tạo fallback definition im lặng.
- Missing optional cosmetic có thể dùng fallback presentation nếu contract subtype ghi rõ; missing gameplay field luôn là lỗi.
- Renaming/removing ID cần ADR hoặc migration table và compatibility test.
