# Kiến trúc module Paloria 3.0

## Luồng phụ thuộc mục tiêu

```text
Input/UI intent
      ↓
Application coordinators (player, world, base)
      ↓
Domain systems (combat, capture, inventory, jobs, farming, crafting)
      ↓
Typed definitions + pure state
      ↓
Presentation adapters (animation, VFX, audio, camera, HUD)
```

Domain không truy cập HUD. UI không sửa inventory, HP, pet hoặc Node world trực tiếp. Node presentation nhận event/result và không quyết định damage, capture hay reward.

## Catalog module

| ID | Module mục tiêu | Hiện trạng/owner | Contract mục tiêu | Work package |
|---|---|---|---|---|
| CORE | Clock, RNG, command/result, IDs | `ContentId` đã có; clock/RNG/result chưa tách | Kiểu dữ liệu thuần, deterministic, không phụ thuộc scene | U1.1, package sau |
| DATA | Definition registry | Item/Recipe/Building/Crop typed canary; registry validate duplicate, field và missing reference | Typed Resource, ID ổn định, validator | U1.1–U1.3 |
| PLAYER | Input, locomotion, needs, progression coordinator | Needs/locomotion pure; action input dùng stable intent/mapper/policy; progression/craft/build handler còn trong `player.gd` | Gọi component con; phát snapshot/event | U1.4–U1.6 |
| COMBAT | Damage, status, targeting, hit result | Pure DamageRequest/Result migrated vào Player + WildCreature; caller khác qua adapter | Command → deterministic result; presentation riêng | U1.5 |
| CAPTURE | Throw, chance, result, ownership | Pure chance + sphere transaction + ownership resolver; stable species adapter; atomic roster commit | Seeded/injected RNG; ownership update một lần | U1.7 |
| CREATURE | Wild AI, ecology, locomotion | Năm species typed stats/skills/drop; ecology lifecycle dùng policy owner | Burn/status writer và progression reward | U1.9 |
| PET | Party, command, combat assist | `pet.gd`, `player.gd` | PetInstance state + PetCommand; không giữ Node trong save | U1.10 |
| JOBS | Pet work/reservation | Scan group trong `pet.gd`, từng building | Job board, reservation, capability, result | U5.2 |
| INVENTORY | Stack, transfer, equipment, loot | Stable transactions; chest finite stack slots và atomic mapped batch; other direct writers còn legacy | ID-based transaction atomic | U1.2, U1.4 |
| CRAFT | Recipe/cooking/smelting/compost | `RecipeDefinition` canary tồn tại; Player + 3 building scripts vẫn authoritative | RecipeDefinition + CraftOrder state machine | U1.3, U5.4 |
| FARM | Soil/crop/water/fertilizer/harvest | `CropDefinition` berry mirror; `resource_node.gd` vẫn gộp resource và plot | FarmPlot state thuần + CropDefinition | U1.3, U5.3 |
| BUILD | Placement, cost, structure health | `BuildingDefinition` workbench mirror; Player + building scripts vẫn authoritative | PlacementRequest/Result, occupancy grid | U1.3, U1.6, U5.5 |
| BASE | Base level, quest/progression | `base_manager.gd` | Progression state đọc event domain | U5.6 |
| WORLD | Zone, chunks, spawn, day/night, raid | `main.gd`, scene tĩnh | Chunk admission + persistent delta | U2 |
| NAV | Navigation/path requests | Chưa có | Navigation adapter theo chunk | U2.3 |
| SAVE | Versioned persistence | Save v1 schema, Player/base adapters, atomic repository, migration registry và explicit coordinator | Autosave/UI scheduling, world/building DTO | U1.11–U1.12 |
| UI | HUD, menus, ViewModel, settings | `hud.gd`, `hud.tscn` | Intent signals + immutable snapshots | U3 |
| PRESENT | Animation/VFX/camera/audio | Trộn trong actor; `AudioManager` autoload | Event-driven adapters, pooling, accessibility scale | U4 |
| ASSET | Vendoring/provenance/import | File rời, nguồn chưa biết | Manifest, package receipt, immutable vendor source | U0.2, U4.1 |
| QA | Validation/smoke/performance | `tools/check_project.ps1` | Layered gates và reproducible scenario | Mọi package |

## Contract chi tiết

### CORE và DATA

- ID dùng ASCII ổn định: `creature.foxfire`, `item.wood`, `recipe.pal_sphere.basic`, `building.workbench`.
- Tên, mô tả và text UI là localization key; không dùng text hiển thị làm key inventory/save.
- Definition bất biến trong runtime. State instance chỉ lưu ID và giá trị thay đổi như HP, level, durability.
- Registry fail sớm khi duplicate ID, resource thiếu, giá trị âm, recipe cycle hoặc asset path không tồn tại.
- U1.3 cross-reference pass chạy sau register toàn catalog; schema và typed-mirror boundary ở `DOMAIN_DEFINITIONS.md`.
- Contract thực thi hiện tại được mô tả tại `docs/architecture/DATA_CONTRACTS.md`. `tools/validate_content.gd` là gate cho grammar, duplicate và toàn bộ definition tree.
- U1.12b thêm runtime inventory manifest: 25 key reachable phải có mapping hai chiều và typed item definition; localized key chỉ còn là compatibility storage.

### PLAYER

- Nhận input qua command (`Move`, `Attack`, `Interact`, `Build`, `PetCommand`).
- Locomotion sở hữu velocity/sprint/roll; Needs sở hữu hunger/thirst/temperature; Progression sở hữu level/EXP/stat points.
- U1.6a thực thi Needs bằng `PlayerNeedsState`; `tick(delta, is_sprinting, near_heat)` trả result/snapshot, stable buff ID dùng namespace `needs.buff.*`. Contract chi tiết ở `PLAYER_NEEDS_CONTRACT.md`.
- U1.6b thực thi locomotion bằng `PlayerLocomotionState`; typed movement input + result quyết định stamina/sprint/roll/desired velocity. Contract chi tiết ở `PLAYER_LOCOMOTION_CONTRACT.md`.
- U1.6c map physical event thành `PlayerActionIntent`, áp pure guard rồi coordinator mới gọi handler. Contract chi tiết ở `PLAYER_ACTION_CONTRACT.md`.
- Player còn đọc thiết bị, dispatch handler domain, dò heat source, áp collision/visual và proxy field legacy; HUD chỉ nhận projection.
- Player coordinator không chứa catalog recipe/building/species.
- Mỗi frame chỉ có một state locomotion có quyền ghi velocity; invulnerability có thời điểm bắt đầu/kết thúc rõ.

### COMBAT và CAPTURE

- DamageRequest gồm source ID, target ID, base damage, element/tags và hit position.
- DamageResult gồm applied damage, critical/status/knockback, defeated flag; VFX đọc result.
- Contract thực thi U1.5, rule order và legacy paths nằm trong `COMBAT_CONTRACT.md`.
- CaptureRequest/Result U1.7a dùng injected roll, HP/sphere/status/back-strike scalar; Creature resolve trước animation và commit result một lần. Chi tiết ở `CAPTURE_CONTRACT.md`.
- U1.7b sphere selection dùng stable IDs và atomic inventory remove; projectile/missed drop giữ ID xuyên boundary.
- U1.7c ownership resolver nhận hai roll đã inject; Player commit party/reward một lần và WildCreature chỉ despawn sau accepted. Contract ở `CAPTURE_OWNERSHIP_CONTRACT.md`; persistent PetInstance/save còn U1.10–U1.11.
- Một hitbox chỉ gây damage một lần cho mỗi target trong một activation.
- Capture chance được clamp, log được input và roll; thành công chuyển ownership đúng một lần và despawn wild instance sau khi party/state nhận dữ liệu.

### CREATURE và PET

- CreatureDefinition chứa stats, element, behavior profile, skill IDs, drops, capture difficulty và animation set.
- U1.8a player perception dùng pure candidate/request/result policy và cadence 0,20 giây; protected state bỏ qua group query. Contract và scan audit ở `CREATURE_PERCEPTION_CONTRACT.md`.
- U1.8b–U1.8c dùng stable transition request/result và một apply boundary cho IDLE/WANDER/SUSPICIOUS/ALERT/CHASE, natural timeout, FLEE và capture rejection; stale/protected/SET thiếu target không mutate. Contract ở `CREATURE_TRANSITION_CONTRACT.md`.
- Random natural-state entry, charge/species attack, damage reaction và pack/predator-prey writer được phân loại sang U1.9 definition/skill/ecology packages.
- U1.9a thêm `CreatureDefinition` + embedded `CreatureBehaviorProfile`; `creature.flam` là runtime canary qua `LegacySpeciesAdapter`, không còn duplicate six gameplay fields trong row dictionary. Contract ở `CREATURE_DEFINITION_CONTRACT.md`.
- U1.9b thêm `SkillDefinition`; `creature.flam` tham chiếu `skill.flam.fireball`, còn actor adapter chỉ thi hành scene/tween/damage guard. Contract và remaining-writer audit ở `CREATURE_SKILL_CONTRACT.md`.
- U1.9c thêm `CreatureDropRequest/Result/Resolver`; Flam defeat drop commit một lần bằng stable item ID, còn actor chỉ spawn node từ accepted result. Contract ở `CREATURE_DROP_CONTRACT.md`.
- U1.9d thêm `CreatureEcologyRequest/Result/Policy` cho damage panic; accepted decision đi qua stable transition event và apply owner. Contract ở `CREATURE_ECOLOGY_CONTRACT.md`.
- U1.9e thêm deterministic nearest prey selection với scan-local key/tie-break; group scan chỉ thu candidate và actor apply accepted result. Contract tiếp tục ở `CREATURE_ECOLOGY_CONTRACT.md`.
- U1.9f thêm pure grazing decision với injected roll và stable transition; short-circuit RNG của sleep/drink/grazing/wander giữ nguyên. Contract tiếp tục ở `CREATURE_ECOLOGY_CONTRACT.md`.
- U1.9g đóng hunt abort/contact bằng stable transition events; ecology `prey_target` chỉ clear sau accepted apply, trong khi tốc độ, contact, damage và recovery giữ nguyên.
- U1.9h đóng predator-threat callback bằng stable transition; FLEE 4 giây, target và presentation giữ compatibility, stale/protected apply bị chặn.
- U1.9i thêm pure sleep decision/injected roll và stable transition; peaceful guard, strict 0.18 boundary, duration 6–11 giây cùng natural-action RNG ordering được giữ.
- U1.9j thêm pure drinking decision bằng water/distance/roll snapshot; strict 320px/0.25 boundary, duration 3–5 giây, pond direction và RNG ordering được giữ.
- U1.9k thêm `creature.slime` typed definition; runtime adapter chiếu stat/prey role/drop reference, giữ presentation và hop/drop execution compatibility.
- U1.9l thêm `creature.mushroom` typed definition và berry-seed legacy mapping; giữ presentation, spore attack và drop execution compatibility.
- U1.9m thêm `creature.beast`, `item.fresh_meat` và legacy mapping; giữ presentation, charge attack, inventory key và drop execution compatibility.
- U1.9n thêm `creature.dragon`, `item.pal_ingot` và legacy mapping; giữ forced-elite scaling, presentation, melee/fireball, inventory key và drop execution compatibility.
- U1.9o thêm `skill.dragon.fireball` với balance identity riêng; actor dispatch dùng typed tuning, giữ melee priority, projectile presentation và stale lifecycle guards.
- U1.9p thêm `skill.mushroom.spore`; actor dùng typed projectile tuning, giữ kiting/escape, presentation và lifecycle compatibility.
- U1.9q thêm `HopSkillDefinition` và `skill.slime.hop`; giữ hop velocity/height cùng bốn nhịp squash/stretch.
- U1.9r thêm `ChargeSkillDefinition` và `skill.beast.charge`; FSM giữ transition/contact/wall ownership.
- U1.9s thêm species-specific Beast/Dragon `MeleeSkillDefinition`; giữ target, damage adapter và recovery lifecycle.
- U1.9t route defeat drop của đủ năm species qua deterministic result + atomic commit; xóa localized legacy spawn writer.
- U1.9u route burn tick qua `DamageRequest/CombatResolver`; actor giữ cadence và presentation nhưng không còn direct HP writer.
- U1.10a thêm typed `PetInstance` projection với unique `pet.*` ID + stable species ID; capture resolver tạo party entry, roster dictionary vẫn là single source compatibility.
- U1.10b thêm pure summon policy và active instance ID; replace tháo node cũ khỏi tree trước spawn, same-instance là no-op để không reset/duplicate.
- U1.10c thêm stable cycle-stance command cùng pure policy/result; CompanionPet sở hữu apply, Player chỉ dispatch và render HUD result.
- U1.10d thêm explicit stance commands và idempotent `NO_CHANGE`; target/job command mở rộng được hoãn sang U5.
- PetInstance lưu unique ID, species ID, level/EXP, stats rolled, needs, skills và assignment.
- Pet command tối thiểu: follow, guard, attack target, work, return. Job và combat không đồng thời sở hữu locomotion.

### INVENTORY, CRAFT, FARM và BUILD

- Mọi mutation inventory là transaction: kiểm tra đủ → commit toàn bộ → phát một event; thất bại không trừ dở dang.
- Boundary chuyển tiếp U1.2 được mô tả trong `INVENTORY_MIGRATION.md`: `item.wood` route về key `Gỗ`, không tạo store song song; pickup chỉ biến mất khi add trả thành công.
- U1.4a transaction/result và direct-writer audit nằm trong `INVENTORY_TRANSACTIONS.md`; policy hiện tại là unlimited và không truy cập SceneTree.
- Recipe chỉ tham chiếu item ID và số lượng dương. CraftOrder có pending/running/completed/cancelled.
- Farm plot lưu crop ID, planted time/progress, moisture và fertilizer effect; visual stage là projection của state.
- Placement xác nhận cost, bounds, collision, terrain và authority trước khi tạo building; hủy build không mất item.

### WORLD, NAV và SAVE

- Chunk key + local entity ID tạo identity bền vững. Unload ghi delta trước khi free Node.
- Spawn budget theo biome/time; không respawn entity đã captured/harvested trước cooldown đã lưu.
- Save gồm `schema_version`, metadata và DTO theo module; ghi file tạm rồi replace để tránh corrupt.
- Load migration tuần tự `vN → vN+1`; thiếu content ID trả lỗi có ngữ cảnh hoặc dùng fallback đã ghi rõ.
- U1.11a thêm `SaveV1Schema`/`SaveValidationResult`: validate player/inventory/pets/world bằng stable ID, unique reference và JSON-safe values; chưa đọc/ghi file.
- U1.11b thêm `SaveSnapshotAdapter`: runtime Player/inventory/party → deep-copied validated DTO; unknown legacy inventory key fail closed, không partial snapshot.
- U1.11c thêm `SaveApplyPlan/Result/Adapter`: validate và resolve mọi stable reference trước commit Player/inventory/party; lỗi giữ runtime source, world clock trả về caller.
- U1.11d thêm `SaveRepository/Result`: validate-before-write, temp verification, primary→backup rotation và read-only backup recovery; chưa nối gameplay/autosave/UI.
- U1.11e thêm `SaveMigrationRegistry/Step/Result`: sequential injected route, cycle/missing/future/ambiguous/output guards; production chưa có pre-v1 step.
- U1.11f thêm `SaveCoordinator/Result`: snapshot→repository và repository→migration→apply, phân biệt primary/backup recovery và handoff world clock.
- U1.12a audit xác nhận SAVE mới phủ Player/core roster; inventory key chưa admit có thể block toàn snapshot, còn base/building/crop/world delta chưa có owner DTO. Ma trận ở `PERSISTENCE_COVERAGE_AUDIT.md`.
- U1.12b đóng blocker inventory đã audit: snapshot regression theo core/crafting/farming/ranch/cooking; unknown key vẫn fail closed. Pet metadata và world/base coverage chưa đổi.
- U1.12c thêm `PetMetadataCatalog`, stable rarity/trait/stance trong roster và Save v1; Player persist stance trước node replacement và restore khi summon. Presentation text/behavior giữ nguyên.
- U1.12d thêm PROGRESSION boundary `BaseQuestCatalog`/`BaseProgressState`; BaseManager sở hữu claimed ledger, Save v1 snapshot/apply stable base state mà không phát reward. World/building DTO chưa đổi.
- U1.12e thêm BUILDING placement catalog/record; U1.12f–j thêm typed chest, processing và ranch state với staged restore. Crop/health/altar/turret state chưa persist.

### UI và PRESENTATION

- UI phát intent, coordinator xử lý và trả ViewModel/snapshot. Modal quản lý focus và pause policy.
- Animation marker phát event presentation; kết quả combat/craft không phụ thuộc frame animation đã render.
- Screen shake, flash và motion có multiplier hoặc tắt được. Audio API nhận semantic event thay vì đường dẫn asset từ gameplay.

## Hợp đồng SceneTree hiện tại cần bảo toàn khi refactor

| Group | Producer | Consumer hiện tại | Kế hoạch thay thế |
|---|---|---|---|
| `player` | `player.gd` | creature, pet, dropped item, farm | Player service/reference được inject |
| `wild_creatures` | `creature.gd` | main, pet, turret, slash | Spatial query/perception service |
| `companion_pets` | `pet.gd` | player, furnace, quest | Pet roster + nearby query |
| `resource_nodes` | `resource_node.gd` | pet jobs | Job board/spatial index |
| `dropped_items` | `dropped_item.gd` | pet jobs | Loot pickup service |
| `hud` | `main.gd` | player/base/building | UI presenter reference/signals |
| `buildings`, subtype groups | building scripts | quest/interaction/automation | Building registry |
| `heat_sources` | cooking pot | player temperature | Environment influence service |

Không xóa group trong cùng package tạo service mới. Chạy song song qua adapter, chuyển consumer từng bước, rồi xóa contract cũ sau khi có test.

## Quy tắc thay đổi module

Mỗi module mới cần: owner path, public types/API, signals/events, invariant, dependency cho phép, save impact, test và mục tương ứng trong `docs/gameplay/FEATURES.md`. Nếu một thay đổi chạm hơn ba module, phải chia adapter/migration thành nhiều package.
