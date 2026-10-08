# U1.12a — Audit coverage persistence của vertical slice

Ngày audit ban đầu: 2026-10-06. Re-audit U1.12ah và closure audit U1.12ak: 2026-10-08. Đây là bằng chứng tĩnh từ owner/runtime hiện tại; package audit không đổi schema hoặc gameplay.

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
| `Player` | `max_exp`, `stat_points`, `stats`, weapon/armor, needs maxima và stable food buff/duration | `PlayerProgressionState`, `equipment.*`, `needs.buff.*` | Typed snapshot/apply regression U1.12ai–aj | Threshold, allocation, gear, maxima và buff giữ coherent | FULL |
| `Player.inventory` | 25 key reachable trong manifest core/crafting/farming/ranch/cooking | `item.*`; localized key chỉ là compatibility storage | Có round-trip và snapshot regression theo nhóm | Các output đã audit giữ được; unknown key vẫn fail closed | FULL trong manifest (U1.12b) |
| `Player.pet_party` / `CompanionPet` | instance/species/level/exp, rarity, trait, stance từng pet và active instance | `pet.*`, `creature.*`; badge/name chỉ presentation | Có snapshot/apply regression active + inactive | Core roster và command state giữ được | FULL trong contract U1.12c |
| `BuildingRanch` | assigned pets, food, production timer, health | `building.instance_*`, stable assignment/species IDs | Typed subtype round-trip U1.12j/q | Assignment, timer, presentation count và durability giữ được | FULL |
| `BaseManager` | base level, active quest, claimed reward ledger | `quest.base.*` + typed `BaseProgressState` | Snapshot/apply regression | Progress giữ được; claimed quest không phát reward lại | FULL trong contract U1.12d |
| Building placement | subtype + transform + admitted subtype state | `building.*` và `building.instance_*` | Chín subtype có parser/apply; durability có ở subtype destructible đã admit | Player-created building và committed state giữ được | FULL trong Save v1 |
| `BuildingChest` | stored items, health | Building instance + `item.*` | Typed round-trip U1.12f/n | Kho và durability giữ được | FULL |
| Furnace/compost/cooking | input/output queue, timer, ready count; durability nơi gameplay có health | Building instance + stable recipe/item IDs | Typed round-trip U1.12g–i/o–p | Transaction đang xử lý giữ được | FULL trong contract hiện tại |
| `ResourceNode` farm plot | crop type/stage, growth timer, moisture, watered/fertilized | Building instance + stable crop/stage IDs | Typed round-trip U1.12k | Tiến độ và đầu tư giữ được | FULL |
| Static tree/rock | health, depleted state, respawn remaining | `resource.tree_1..6`, `resource.rock_1..4` | Typed resource delta U1.12u/v | Static resource giữ được; chunk-spawned resource chưa tồn tại | FULL trong world tĩnh hiện tại |
| `main.gd` clock | `day_time` | Scalar `world.clock_seconds` | Main explicit save/load boundary commit sau success | Clock round-trip; raid/boss/spawn timers vẫn riêng | FULL (clock) |
| `main.gd` encounter | raid-cycle, world boss và night raid lifecycle/remaining roster | Stable boss/raid encounter + actor slot IDs | Typed Save v1 round-trip U1.12x–ag | Boss/raid không duplicate hoặc reroll khi load | FULL cho boss/raid |
| `main.gd` ambient wild population | transient creature roster/species/position/HP | Không có instance identity | Không | Wild population được tái tạo từ scene/spawn director sau reload | MEDIUM/NONE; cần quyết định U2 chunk policy |
| `world.entity_deltas` | player-created buildings và static resource deltas | Building/resource instance IDs | Typed payload đã admit | Current static-world delta giữ được; chưa có chunk identity | FULL hiện tại / dependency U2 cho world rộng |

## Bằng chứng file/API

- Save coverage hiện hữu: `systems/save/save_v1_schema.gd`, `save_snapshot_adapter.gd`, `save_apply_adapter.gd`, `save_coordinator.gd` và `tools/validate_save_coordinator.gd`.
- Player/inventory/pet source: `scripts/player.gd`; active stance: `scripts/pet.gd`.
- Base/quest: `scripts/base_manager.gd` project/apply `BaseProgressState`; Save dùng stable `quest.base.*`, còn localized quest dictionary là presentation/compatibility.
- Placement: `scripts/player.gd` cấp `building.instance_*`, snapshot `BuildingPlacementRecord` và apply chín subtype qua catalog.
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

## U1.12aa world-boss actor audit

`boss_spawned` hiện không phân biệt active/defeated; Main không giữ actor reference/stable group và Creature không signal defeat về world owner. `WorldBossState` đã khóa future DTO bằng lifecycle pending/active/defeated, fixed `boss.world_dragon_1`, HP 1–380 và finite position. Coverage vẫn PARTIAL: state chưa thuộc Save v1 cho tới khi actor ownership, defeat callback và reward suppression được triển khai/test.

## U1.12ab world-boss ownership

Main đã sở hữu một actor `boss.world_dragon_1`; duplicate spawn fail closed và defeat signal chỉ commit actor reference/group/ID trùng khớp. Coverage vẫn PARTIAL vì lifecycle/HP/position chưa đi qua Save v1; reward/drop và actor thường/altar không đổi.

## U1.12ac world-boss Save v1

Lifecycle/instance ID/HP/position đã round-trip và Main restore active đúng một actor, defeated/pending không spawn. Invalid/corrupt load không thay actor hiện tại; restore không tạo EXP/drop hoặc presentation. Defeat coverage FULL; capture/despawn ngoài defeat vẫn cần lifecycle event riêng.

## U1.12ad world-boss capture lifecycle

Accepted capture phát stable removal reason và Main terminal-commit đúng owned world boss trước actor free. Reject/duplicate/foreign actor không mutate; save sau captured state không respawn. World-boss defeat + capture coverage hiện FULL; generic external despawn vẫn fail snapshot thay vì suy đoán lifecycle.

## U1.12ae night-raid actor audit

Ba raid actor hiện không có stable identity/reference và owner không nhận defeat/capture removal; guard true không phân biệt active/cleared. Pure `NightRaidState` đã khóa cycle-scoped encounter cùng ba actor slot, resolved species, level/HP/position và JSON validation. Coverage vẫn PARTIAL; chưa admit Save v1 hoặc spawn khi load.

## U1.12af night-raid runtime ownership

Main nay sở hữu map ba stable raid slot, metadata/group encounter và aggregate đúng owned defeat/captured removal thành remaining roster hoặc CLEARED. Foreign/duplicate callback và duplicate trigger fail closed. Coverage vẫn PARTIAL vì Save v1 chưa snapshot/apply raid DTO và chưa restore actor.

## U1.12ag night-raid Save v1

Typed raid lifecycle và remaining roster đã đi qua schema/snapshot/apply/coordinator. Main restore ACTIVE từ resolved state không RNG/presentation/reward; CLEARED/PENDING không spawn; legacy missing field suy ra bảo thủ. Coverage raid hiện FULL về defeat/capture/save; cần chạy Godot gate trước khi đánh dấu VERIFIED và re-audit các gap persistence còn lại.

## U1.12ah coverage re-audit

Full gate U1.12ag và strict log scan đã xanh ngày 2026-10-08. Re-audit source xác nhận các hàng building/farm/static resource/boss/raid cũ trong ma trận đã bị lịch sử triển khai U1.12e–ag làm lỗi thời; chúng được nâng lên FULL trong phạm vi world tĩnh hiện tại.

Gap HIGH có bằng chứng trực tiếp còn lại là Player progression/gear/needs metadata: `player.gd` giữ `max_exp`, `stat_points`, bốn stat, `weapon_name`/`weapon_damage`, `has_armor`; `PlayerNeedsState` giữ maxima cùng stable `buff_id`/remaining duration, nhưng Save v1 chỉ mang level/EXP, scalar needs hiện tại và stamina. Reload vì vậy có thể tạo trạng thái không nhất quán (ví dụ level/EXP đã restore nhưng threshold/stat/gear về mặc định). U1.12ai phải audit invariants và tạo typed contract trước admission; không serialize localized `weapon_name`, không tin `weapon_damage` derived và không mở rộng sang wild population/chunk identity.

## U1.12ai Player progression contract

Pure `PlayerProgressionState` nay khóa level/EXP threshold, stat budget, stable equipment/buff identity và coherent derived maxima. `PlayerEquipmentCatalog` thay localized name/damage làm boundary identity/authority. Coverage vẫn PARTIAL vì Save v1 và Player adapter chưa mang typed state; U1.12aj là admission gate kế tiếp.

## U1.12aj Player progression Save v1

Snapshot/apply nay round-trip typed progression state, stable gear, derived maxima và needs buff metadata; invalid state fail trước mutation, legacy missing field nhận conservative defaults. Hàng Player progression/gear/needs trong ma trận được nâng lên FULL trong contract hiện tại. Gap persistence còn lại cần re-audit riêng trước khi tuyên bố đạt gate U1; ambient wild population vẫn thuộc U2 chunk policy.

## U1.12ak persistence closure audit

Đối chiếu lại owner runtime với schema, snapshot, apply và regression sau U1.12aj xác nhận không còn gap `HIGH`, `CRITICAL` hoặc `BLOCKER` trong phạm vi vertical slice/world tĩnh. Player core/progression/inventory/pet, base quest, chín building subtype, farm plot, static resource, clock, world boss và night raid đều có stable identity cùng round-trip regression.

Các phần cố ý không thuộc closure:

- Ambient wild population là `MEDIUM/NONE`: actor thường là population tái tạo, chưa có chunk/spawn instance identity. Quyết định persist/despawn delta thuộc U2 sau khi chốt chunk coordinate và spawn director; không được thêm identity tạm trong Save v1.
- Input/build preview, attack/sphere cooldown, roll/animation/VFX, target Node, tween và capture token đang bay là transient chưa commit, không phải persistence gap.
- Autosave scheduling và slot UI không thay đổi explicit-save data coverage; route sang U3 UI/UX. Multi-slot corruption/recovery hardening cuối cùng vẫn thuộc U6.

Kết luận: U1.12 persistence coverage đủ điều kiện `VERIFIED`. Gate U1 tổng thể chưa đóng vì tiêu chí giảm trách nhiệm Player/Creature chưa có baseline/threshold đạt gate: tại audit, `scripts/player.gd` có 1.262 dòng, `scripts/creature.gd` có 1.523 dòng, và craft/build handler vẫn authoritative trong Player. U1.13 phải đo ownership/writer surface và chốt extraction nhỏ cần thiết trước khi quyết định chuyển U2; đây là gap kiến trúc, không phải gap Save.

## U2.3 chunk delta attribution

Building placement và static resource depletion nay có chunk-scoped envelope với deterministic signed key. Save/load giữ backward compatibility với flat U1 lists; invalid/cross-chunk identity fail atomic. Coverage không mở sang ambient wild population vì spawn identity vẫn phụ thuộc U2.5.

## U2.6 discovery persistence audit

Discovery là world progression state mới: runtime owner `ChunkDiscoveryState` có canonical chunk keys, revision và JSON-safe DTO nhưng Save v1 hiện không snapshot/apply field này. Đây là coverage `NONE/MEDIUM` trong U2: reload trả state rỗng nên fog có thể che lại vùng đã khám phá, nhưng không làm mất inventory/building/encounter state. Không admit field trong U2.6 foundation để tránh mở schema cùng lúc với contract; package U2.6b phải nối snapshot/apply/coordinator với legacy missing-field fallback rỗng trước khi fast travel dùng discovery làm điều kiện.

Ambient U2.5 vẫn transient theo quyết định riêng; discovery DTO không chứa ambient actor, Node, navigation RID hoặc scene path.

U2.6b đã nâng discovery lên `FULL` trong contract hiện tại: primary/backup round-trip exact set, legacy missing-field fallback rỗng, corrupt/apply failure giữ runtime state và restore không phát side effect chunk/navigation/spawn. Ambient actor/cooldown vẫn là gap transient riêng, không nằm trong discovery DTO.
