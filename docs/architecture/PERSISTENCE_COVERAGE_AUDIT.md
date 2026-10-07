# U1.12a — Audit coverage persistence của vertical slice

Ngày audit: 2026-10-06. Đây là bằng chứng tĩnh từ owner/runtime hiện tại; package này không đổi schema hoặc gameplay.

## Cách phân loại

- `FULL`: state bền vững cần thiết đã có stable identity, snapshot và apply regression.
- `PARTIAL`: chỉ một phần state được round-trip hoặc mới có handoff nhưng chưa có owner commit.
- `NONE`: state mutable chắc chắn trở về mặc định/mất khi reload.
- `BLOCKER`: state có thể khiến explicit save thất bại hoàn toàn, không chỉ mất một field.

Transient animation, cooldown ngắn, target Node, tween và VFX không được coi là persistence gap trừ khi chúng quyết định transaction chưa commit.

## Ma trận owner → identity → coverage

| Owner/runtime source | State bền vững quan sát được | Stable identity hiện tại | Snapshot/apply | Rủi ro reload | Mức |
|---|---|---|---|---|---|
| `Player` | position, level/EXP, HP/max HP, stamina, hunger/thirst/temperature | `save.*`; scalar DTO | Có regression end-to-end | Giữ được các field đã liệt kê | FULL |
| `Player` | `max_exp`, `stat_points`, `stats`, weapon/armor, needs maxima và food buff/duration | Chưa có contract save | Không | Build nhân vật/progression phụ trở về mặc định | HIGH/PARTIAL |
| `Player.inventory` | 25 key reachable trong manifest core/crafting/farming/ranch/cooking | `item.*`; localized key chỉ là compatibility storage | Có round-trip và snapshot regression theo nhóm | Các output đã audit giữ được; unknown key vẫn fail closed | FULL trong manifest (U1.12b) |
| `Player.pet_party` / `CompanionPet` | instance/species/level/exp, rarity, trait, stance từng pet và active instance | `pet.*`, `creature.*`; badge/name chỉ presentation | Có snapshot/apply regression active + inactive | Core roster và command state giữ được | FULL trong contract U1.12c |
| `BuildingRanch` | assigned pets, food, production timer, health | Không có building instance ID; assignment dùng dictionary/name | Không | Assignment/output progress mất; starter pet tự sinh lại | CRITICAL/NONE |
| `BaseManager` | base level, active quest, claimed reward ledger | `quest.base.*` + typed `BaseProgressState` | Snapshot/apply regression | Progress giữ được; claimed quest không phát reward lại | FULL trong contract U1.12d |
| Building placement | subtype + transform | `building.*` subtype và `building.instance_*` | Snapshot/apply placement regression | Player-created placement giữ được; subtype state chưa giữ | PARTIAL (U1.12e) |
| `BuildingChest` | stored items, health | Không có building instance ID | Không | Kho đồ mất toàn bộ | CRITICAL/NONE |
| Furnace/compost/cooking | input/output queue, timer, ready count, health | Không có order/instance ID | Không | Mất nguyên liệu hoặc tiến độ đang xử lý | CRITICAL/NONE |
| `ResourceNode` farm plot | crop type/stage, growth timer, moisture, watered/fertilized | `crop.berry` chỉ là typed canary; plot không có instance ID | Không | Cây trồng và đầu tư nước/phân trở về mặc định | CRITICAL/NONE |
| Resource/tree/rock | health/depleted existence | Scene node name/path tạm thời | Không | Resource bị phá hồi sinh sau reload | HIGH/NONE |
| `main.gd` clock | `day_time` | Scalar `world.clock_seconds` | Main explicit save/load boundary commit sau success | Clock round-trip; raid/boss/spawn timers vẫn riêng | FULL (clock) |
| `main.gd` encounter | raid-cycle flag, boss spawned/timer/defeat, wild population | Không | Không | Raid/boss có thể spawn lại hoặc reset timer | HIGH/NONE |
| `world.entity_deltas` | placeholder Array | Chưa có entity/chunk instance identity | Schema shape có, payload chưa admit | Không thể giữ building/crop/resource changes | CRITICAL/NONE |

## Bằng chứng file/API

- Save coverage hiện hữu: `systems/save/save_v1_schema.gd`, `save_snapshot_adapter.gd`, `save_apply_adapter.gd`, `save_coordinator.gd` và `tools/validate_save_coordinator.gd`.
- Player/inventory/pet source: `scripts/player.gd`; active stance: `scripts/pet.gd`.
- Base/quest: `scripts/base_manager.gd` giữ `base_level`, `current_quest_idx`, `quest_completed` và dùng localized quest dictionaries.
- Placement: `scripts/player.gd::place_current_building()` instantiate Node trực tiếp, chỉ gắn transform; không cấp instance ID.
- Building mutable state: `scripts/building_chest.gd`, `building_furnace.gd`, `building_compost_bin.gd`, `building_cooking_pot.gd`, `building_ranch.gd`, `building_altar.gd`.
- Crop/resource state: `scripts/resource_node.gd`; clock/raid/boss: `scripts/main.gd`.

## Gap ưu tiên cho U1.12b

Ưu tiên **đóng tập identity inventory runtime** trước. Lý do:

1. Đây là gap duy nhất hiện làm `SaveCoordinator.save_player()` thất bại nguyên khối ngay sau các loop farming/crafting/cooking/ranch bình thường.
2. Nó là dependency cho chest, processing queue, crop harvest và quest snapshot sau này; nếu item chưa có stable ID thì các DTO domain đó cũng không thể hợp lệ.
3. Có thể sửa trong một package data/validator độc lập, không cần vội thiết kế world entity identity.

U1.12b đã tạo manifest gồm 25 key, admit 14 `item.*` definition/mapping còn thiếu và chứng minh snapshot Player cho từng nhóm không còn `UNMAPPED_ITEM`. Backing dictionary và economy không đổi. Rủi ro còn lại: source producer mới phải được thêm vào manifest bằng review; validator khóa tính toàn vẹn manifest nhưng chưa tự phân tích source để phát hiện key mới.

## Thứ tự sau U1.12b

1. Pet rarity/trait/inactive stance dùng stable IDs và round-trip roster — đóng ở U1.12c.
2. Base/quest typed state để chặn reward lặp — đóng ở U1.12d.
3. Building instance identity + placement delta — đóng ở U1.12e; subtype state/chest/processing tiếp theo.
4. Farm plot/resource delta trên cùng world entity identity.
5. World owner commit clock và encounter persistence.

Save/data breaking change trong audit: none. Asset/provenance: none.

## U1.12u tree depletion

Sáu tree tĩnh trong `main.tscn` có stable instance ID `resource.tree_1`…`resource.tree_6`; subtype là `resource.tree`. Save giữ health và respawn time còn lại, validate coherence trước commit rồi apply trực tiếp không gọi hit/break/drop flow. Coroutine respawn của riêng tree được thay bằng timer deterministic trong `_process`; rock vẫn dùng lifecycle cũ và chưa persist. Save v1 cũ thiếu `resource_deltas` vẫn load như state mặc định của scene.

## U1.12v rock depletion

Bốn rock tĩnh có ID `resource.rock_1`…`resource.rock_4` và subtype `resource.rock`. `ResourceDepletionState` nhận max health từ subtype khi parse record, nên tree không nhận health 61–80 và rock không vượt 80. Rock dùng cùng deterministic respawn countdown; restore không chọn/serialize texture ngẫu nhiên và không chạy hit/drop/VFX. Tree + rock static depletion hiện FULL; chunk-spawned resource chưa tồn tại.

## U1.12w world clock owner

Main truyền `day_time` khi save và chỉ commit clock trả về sau load primary/backup thành công. Failed load giữ clock runtime; apply clock refresh ambient nhưng không tự chạy raid/boss/spawn transaction. Regression chạy Main scene thật qua repository JSON, đồng thời khóa resource health JSON-integer compatibility. Raid-cycle flag, boss và spawn timers vẫn là gap encounter riêng.

## U1.12x raid-cycle guard

Clock và `raid_triggered_this_cycle` round-trip atomically qua Main boundary. Guard true trước phase 0.72 fail schema; load active-night không gọi raid spawn và failed load giữ cả hai runtime fields. Raid creature Node không persist; boss/spawn timers vẫn PARTIAL.

## U1.12y boss timer/guard

Pre-spawn boss countdown và spawned guard round-trip trong typed cycle state. Invalid spawned+pending-timer bị reject trước mutation; load chỉ gán scalar nên không tạo boss actor. Boss actor HP/lifecycle sau spawn và ambient spawn timer vẫn PARTIAL.

## U1.12z ambient spawn timer

Ambient countdown round-trip trong `(0,4]`, default-compatible 3 giây. Load không gọi creature maintenance và failed load giữ timer runtime. Creature roster, random species/offset và chunk spawn identity không persist.
