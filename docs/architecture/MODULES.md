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
| CREATURE | Wild AI, ecology, locomotion | Perception pure + cadence; transition owner cho IDLE/WANDER/SUSPICIOUS/CHASE-loss; lifecycle/skills còn legacy | Basic lifecycle closure và CreatureDefinition | U1.8–U1.9 |
| PET | Party, command, combat assist | `pet.gd`, `player.gd` | PetInstance state + PetCommand; không giữ Node trong save | U1.10 |
| JOBS | Pet work/reservation | Scan group trong `pet.gd`, từng building | Job board, reservation, capability, result | U5.2 |
| INVENTORY | Stack, transfer, equipment, loot | Stable transactions; chest finite stack slots và atomic mapped batch; other direct writers còn legacy | ID-based transaction atomic | U1.2, U1.4 |
| CRAFT | Recipe/cooking/smelting/compost | `RecipeDefinition` canary tồn tại; Player + 3 building scripts vẫn authoritative | RecipeDefinition + CraftOrder state machine | U1.3, U5.4 |
| FARM | Soil/crop/water/fertilizer/harvest | `CropDefinition` berry mirror; `resource_node.gd` vẫn gộp resource và plot | FarmPlot state thuần + CropDefinition | U1.3, U5.3 |
| BUILD | Placement, cost, structure health | `BuildingDefinition` workbench mirror; Player + building scripts vẫn authoritative | PlacementRequest/Result, occupancy grid | U1.3, U1.6, U5.5 |
| BASE | Base level, quest/progression | `base_manager.gd` | Progression state đọc event domain | U5.6 |
| WORLD | Zone, chunks, spawn, day/night, raid | `main.gd`, scene tĩnh | Chunk admission + persistent delta | U2 |
| NAV | Navigation/path requests | Chưa có | Navigation adapter theo chunk | U2.3 |
| SAVE | Versioned persistence | Chưa có | DTO thuần, atomic write, migrations | U1.11 |
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
- U1.8b dùng stable transition request/result và một apply boundary cho 5 block IDLE/WANDER/SUSPICIOUS/CHASE-loss; stale/protected result không mutate. Contract ở `CREATURE_TRANSITION_CONTRACT.md`.
- Wild brain vẫn còn writer lifecycle, combat và ecology; U1.8c đóng basic lifecycle, skill/drop chuyển U1.9.
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
