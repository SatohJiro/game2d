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
| PLAYER | Input, locomotion, needs, progression coordinator | `player.gd` 1.087 dòng | Gọi component con; phát snapshot/event | U1.4–U1.6 |
| COMBAT | Damage, status, targeting, hit result | Player/creature/pet/slash/turret | Command → deterministic result; presentation riêng | U1.5 |
| CAPTURE | Throw, catch chance, capture result | `sphere.gd`, cuối `creature.gd` | CaptureRequest/Result; seeded RNG; ownership update một lần | U1.7 |
| CREATURE | Wild AI, ecology, locomotion | `creature.gd` 1.054 dòng | Brain/state nodes dùng CreatureDefinition | U1.8–U1.9 |
| PET | Party, command, combat assist | `pet.gd`, `player.gd` | PetInstance state + PetCommand; không giữ Node trong save | U1.10 |
| JOBS | Pet work/reservation | Scan group trong `pet.gd`, từng building | Job board, reservation, capability, result | U5.2 |
| INVENTORY | Stack, transfer, equipment, loot | Dictionary tiếng Việt; gỗ có `add/read by ID` qua adapter, chưa có capacity/transaction | ID-based transaction atomic | U1.2, U1.4 |
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
- Player coordinator không chứa catalog recipe/building/species.
- Mỗi frame chỉ có một state locomotion có quyền ghi velocity; invulnerability có thời điểm bắt đầu/kết thúc rõ.

### COMBAT và CAPTURE

- DamageRequest gồm source ID, target ID, base damage, element/tags và hit position.
- DamageResult gồm applied damage, critical/status/knockback, defeated flag; VFX đọc result.
- Một hitbox chỉ gây damage một lần cho mỗi target trong một activation.
- Capture chance được clamp, log được input và roll; thành công chuyển ownership đúng một lần và despawn wild instance sau khi party/state nhận dữ liệu.

### CREATURE và PET

- CreatureDefinition chứa stats, element, behavior profile, skill IDs, drops, capture difficulty và animation set.
- Wild brain chuyển state qua guard rõ; perception không quét toàn bộ group mỗi physics frame.
- PetInstance lưu unique ID, species ID, level/EXP, stats rolled, needs, skills và assignment.
- Pet command tối thiểu: follow, guard, attack target, work, return. Job và combat không đồng thời sở hữu locomotion.

### INVENTORY, CRAFT, FARM và BUILD

- Mọi mutation inventory là transaction: kiểm tra đủ → commit toàn bộ → phát một event; thất bại không trừ dở dang.
- Boundary chuyển tiếp U1.2 được mô tả trong `INVENTORY_MIGRATION.md`: `item.wood` route về key `Gỗ`, không tạo store song song; pickup chỉ biến mất khi add trả thành công.
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
