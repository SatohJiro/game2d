# U1.11a–f — Save v1 end-to-end foundation

## Phạm vi

U1.11a định nghĩa envelope và validation thuần cho Save v1. Package chưa đọc/ghi file, chưa snapshot/apply Node runtime, chưa autosave, checksum, backup, migration hoặc UI slot.

## Envelope v1

```text
{
  schema_version: 1,
  save_id: "save.*",
  saved_at_unix: integer >= 0,
  player: {
    position: { x, y }, level, exp, hp, max_hp,
    stamina, hunger, thirst, temperature,
    active_pet_instance_id: "" | "pet.*"
  },
  inventory: { "item.*": integer >= 0 },
  pets: [{
    instance_id: "pet.*", species_id: "creature.*",
    level: integer > 0, exp: integer >= 0,
    stance_id: "pet.*"
  }],
  world: { clock_seconds: number >= 0, entity_deltas: [] }
}
```

DTO chỉ chứa null/bool/finite number/String/Array/Dictionary với String key. Node, Resource/RefCounted, Callable, Vector2, Color, StringName và object runtime khác bị từ chối. Vector2 được project thành `{x,y}`; stable IDs được lưu dưới dạng String JSON.

Godot parse JSON number về float, nên validator chấp nhận integer hoặc finite float có phần thập phân bằng 0 cho field integer. Số phân số, âm hoặc không finite vẫn bị từ chối.

## Invariant và ownership

- `schema_version` phải đúng 1; version lạ fail closed ở package này.
- `save_id` dùng domain `save`; inventory chỉ dùng `item.*` thay vì localized key.
- Pet instance ID phải unique, species dùng `creature.*`; active pet rỗng hoặc tham chiếu một roster instance.
- Player HP không vượt max HP; count/level/EXP không âm theo contract.
- `world.entity_deltas` là chỗ giữ schema shape cho U2, hiện phải là Array nhưng chưa admit entity delta payload.
- Definition, asset path, texture, scene path, transient Node/ObjectID, capture token, tween và test counters không thuộc save.

`SaveV1Schema.create_empty()` tạo snapshot mặc định JSON-safe; `validate()` không mutate input và trả `SaveValidationResult` cùng danh sách lỗi. Runtime owner sẽ project state sang DTO ở U1.11b; file repository/atomic replace thuộc package sau đó.

## Validation, compatibility và rollback

`tools/validate_save_schema.gd` khóa valid envelope, JSON round-trip, version/shape/range, localized inventory rejection, duplicate/stale pet reference và non-serializable types. Validator được gọi trong `tools/check_project.ps1`.

Save/data breaking change: schema v1 mới được định nghĩa nhưng chưa có file save phát hành, nên không cần migration dữ liệu cũ. Asset/provenance: none. Rollback: revert U1.11a; runtime gameplay không bị ảnh hưởng.

## U1.11b runtime snapshot adapter

`SaveSnapshotAdapter.create_player_snapshot(player, save_id, saved_at_unix, world_clock_seconds)` đọc runtime owner và tạo deep-copied envelope, sau đó bắt buộc chạy `SaveV1Schema.validate()` trước khi trả `ACCEPTED`.

- Player: position được project `{x,y}`; level/EXP/HP/stamina và needs scalar được snapshot, không giữ `PlayerNeedsSnapshot` object.
- Inventory: mọi legacy key phải map hai chiều rõ ràng qua `LegacyItemAdapter`; unknown key trả `UNMAPPED_ITEM` và không trả partial snapshot.
- Pets: party dictionary được project về instance/species/level/EXP. Từ U1.12c, rarity/trait/stance dùng stable IDs; active CompanionPet cung cấp stance hiện tại và roster giữ stance của pet inactive.
- World: package chỉ inject `day_time`/clock scalar từ caller; entity delta vẫn rỗng.
- Snapshot/result deep-copy dữ liệu. Mutation snapshot sau đó không đổi inventory hoặc roster runtime.

U1.11b admit `item.stone` và `item.iron_ingot` cùng definitions/mapping để toàn bộ inventory mặc định project được. Food/fertilizer/crop key legacy chỉ phát sinh ở các loop khác chưa được admit; nếu tồn tại, snapshot fail closed cho tới package migration tương ứng, không silently drop.

## U1.11c atomic runtime apply

`SaveApplyAdapter.apply_player_snapshot(player, snapshot)` luôn chạy `SaveV1Schema.validate()`, sau đó lập `SaveApplyPlan` deep-copy và resolve toàn bộ item/species/stance reference trước mutation. Chỉ plan hoàn chỉnh mới được commit về Player; lỗi shape/version trả `INVALID_SNAPSHOT`, stable ID chưa được runtime admit trả `UNSUPPORTED_REFERENCE`, và nguồn runtime giữ nguyên.

- Stable inventory ID map ngược về đúng một legacy dictionary; không tạo backing store thứ hai.
- Pet DTO được dựng lại thành party entry bằng typed creature definition cùng presentation compatibility trong `LegacySpeciesAdapter`; active instance được summon qua public Player boundary và stance đi qua pet command API.
- Apply result trả `world_clock_seconds` cho world owner tương lai; adapter không tự tìm hoặc mutate world clock Node.
- Position/progression/HP/stamina/needs được commit sau validation. HUD chỉ được refresh sau commit.

Giới hạn tại thời điểm U1.11c là rarity/trait và stance mutable của pet không active chưa nằm trong envelope; gap này được đóng ở U1.12c. File repository, atomic disk replace, autosave, checksum, backup, migration và UI slot vẫn ngoài U1.11c.

## U1.11d atomic JSON repository

`SaveRepository(primary_path)` sở hữu ba path cùng thư mục: primary `.json`, backup `.json.bak` và temporary `.json.tmp`. `save(snapshot)` validate schema trước I/O, ghi + flush temporary, đọc/validate lại temporary rồi mới promote:

1. Primary hợp lệ hiện hữu được rename thành backup sau khi backup cũ được bỏ.
2. Primary hỏng bị bỏ nhưng backup hợp lệ hiện hữu được giữ nguyên.
3. Temporary được rename thành primary; nếu promote thất bại sau rotation, repository thử phục hồi backup về primary.

`load_snapshot()` ưu tiên primary hợp lệ. Khi primary thiếu/hỏng và backup hợp lệ, result trả `RECOVERED_BACKUP` cùng deep-copied DTO nhưng không tự ghi lại primary; read vì thế không có side effect. Không có cả hai file trả `NOT_FOUND`; JSON/schema hỏng trả `INVALID_DATA`; lỗi filesystem trả `IO_ERROR`.

U1.11d chưa có checksum, encryption, migration version, autosave, slot UI hoặc runtime coordinator. Regression dùng thư mục `user://save_repository_test_*` cô lập và dọn primary/backup/temp sau test. Save v1 không đổi shape và chưa có file phát hành cần migration.

## U1.11e migration registry/harness

`SaveMigrationRegistry.migrate(source)` làm việc trên deep copy và trả `SaveMigrationResult`. Registry đọc integer `schema_version`, từ chối version tương lai, rồi đi từng `SaveMigrationStep(from_version, to_version, transform)` cho đến current version. Mỗi bước phải là route duy nhất, Callable hợp lệ và trả Dictionary có đúng declared `to_version`; registry phát hiện missing step, route mơ hồ, cycle và invalid output.

Khi đã tới current version, output bắt buộc qua `SaveV1Schema.validate()`. Input v1 hiện tại là validated no-op (`CURRENT`), không alias source. Do chưa có save format trước v1 được phát hành, production registry hiện không đăng ký step nào; transform v0→v1 chỉ tồn tại trong validator để kiểm tra harness, không phải migration dữ liệu thật.

Repository chưa tự gọi migration trong U1.11e: repository tiếp tục chỉ trả schema v1 hợp lệ. Wiring read → migrate → apply thuộc coordinator kế tiếp, tránh trộn I/O với mutation gameplay.

## U1.11f explicit runtime coordinator

`SaveCoordinator(primary_path, migration_registry)` là application boundary không phải Node/autoload. `save_player(...)` chạy `SnapshotAdapter → Repository`; `load_player(...)` chạy `Repository → MigrationRegistry → ApplyAdapter`. Mỗi stage fail trả `SaveCoordinatorResult` cùng upstream status/errors và không chạy stage sau.

Load success phân biệt `LOADED_PRIMARY` với `LOADED_BACKUP`, đồng thời trả `world_clock_seconds` để world owner commit. Coordinator không giữ state gameplay, không tự pause và không phát UI; caller sở hữu thời điểm gọi và feedback. Scene-level regression dùng Player thật chứng minh primary round-trip, backup recovery và corrupt-both no-mutation.

## U1.12w world clock owner

`main.gd` sở hữu explicit `save_game(saved_at_unix, save_id)` và `load_game()` boundary. Save truyền `day_time` vào coordinator; load chỉ gọi `apply_world_clock()` khi `SaveCoordinatorResult.is_loaded()` đúng, sau đó refresh ambient từ clock mới. Repository/coordinator không tìm scene hoặc mutate Main. Failed repository/migration/apply giữ nguyên runtime clock. `configure_save_path()` cho phép composition/test chọn repository mà không đổi gameplay owner; autosave và UI vẫn ngoài scope.

Resource depletion health parser đồng thời chấp nhận JSON number có giá trị nguyên sau encode/decode, nhưng vẫn từ chối phân số/non-finite; việc này đóng lỗi repository verification của `resource_deltas` mà in-memory schema test trước đó chưa phát hiện.

## U1.12x raid-cycle guard

`world.cycle_state.raid_triggered_this_cycle` đi cùng clock qua snapshot/apply/coordinator result. `WorldCycleState` cho phép guard true chỉ từ phase 0.72 trở đi của chu kỳ 180 giây; false vẫn tương thích save cũ. Main commit clock + guard trong cùng boundary sau load success, không gọi `trigger_night_raid()` và không serialize raid actor/banner/RNG. Boss/spawn timers chưa thuộc DTO.

## U1.12y boss timer/guard

`WorldCycleState` thêm `boss_spawned` và `boss_timer`: pre-spawn dùng timer `(0,50]`; spawned bắt buộc timer 0. DTO cycle một-field cũ mặc định boss chưa spawn/timer 50. Main commit clock/raid/boss scalars atomically sau load success, không gọi `spawn_boss()` và không serialize actor/HP/banner/species presentation. Ambient spawn timer vẫn ngoài scope.

U1.11 foundation kết thúc ở explicit API có kiểm thử. Chưa có autosave, slot UI, pause/transaction scheduling, world entity delta, base/building/crop/quest DTO hoặc checksum. Pet rarity/trait/inactive stance được bổ sung ở U1.12c.

## U1.12b runtime inventory identity closure

`RuntimeInventoryManifest` phân nhóm toàn bộ 25 localized key reachable ở runtime. Mười bốn identity còn thiếu đã có stable `item.*`, typed definition và reverse mapping; snapshot Player được regression riêng cho core/crafting/farming/ranch/cooking nên các output hợp lệ không còn chặn toàn save bằng `UNMAPPED_ITEM`. Adapter vẫn fail closed với key ngoài tập admit và vẫn dùng đúng một legacy backing dictionary. Save v1 shape/economy không đổi.

## U1.12c pet metadata persistence

Mỗi `pets[]` entry bắt buộc có `rarity_id`, `trait_id`, `stance_id` thuộc allowlist stable. Snapshot không ghi badge/trait localized; apply dựng lại presentation bằng `PetMetadataCatalog`. Active actor là authority stance khi snapshot, roster là authority cho pet inactive; Player ghi stance về roster trước khi replace và áp stance roster khi summon.

Đây là thay đổi shape của Save v1 nhưng không tăng `schema_version`: dự án chưa phát hành và chưa có save tương thích được cam kết. Vì vậy migration table vẫn không có pre-v1 route; snapshot thiếu field mới fail validation thay vì tự đoán metadata. Sau bản phát hành đầu tiên, mọi thay đổi shape tiếp theo phải tăng version và có migration step.

## U1.12d base/quest progression

Envelope thêm `base = {base_level, active_quest_id, claimed_quest_ids}`. `BaseProgressState` bắt buộc claimed IDs là prefix catalog, active quest là phần tử kế tiếp và level khớp reward đã claim. Snapshot đọc typed boundary của BaseManager; apply validate/resolve trước mutation và không gọi reward flow. Non-default base state thiếu runtime owner fail closed; Player scene độc lập có thể dùng pristine default.

Shape v1 tiếp tục được cập nhật tại pre-release nên không tăng version; không có migration cho save cũ chưa phát hành. Localized quest title và index không được chấp nhận làm identity.

## U1.12e building placement delta

`world.entity_deltas` hiện chỉ chấp nhận `BuildingPlacementRecord`: unique `building.instance_*`, admitted subtype `building.*` và finite transform. Snapshot đọc Player placement ledger; apply instantiate toàn bộ record trước mutation rồi thay đúng group player-created. Starter scene nodes và subtype state không thuộc DTO này. Shape v1 vẫn pre-release/version 1.

## U1.12f chest subtype state

`BuildingPlacementRecord.state` được validate theo subtype. Chỉ `building.chest` nhận `ChestPlacementState.inventory` với ba stable item ID do chest quản lý; subtype khác bắt buộc state rỗng. Snapshot đọc committed chest store tại lúc save; apply kiểm tra capacity trên shadow store trước khi thay node, vì vậy load không cộng dồn hoặc làm mất item. Chest record U1.12e thiếu state được hiểu là rỗng.

## U1.12g furnace subtype state

`building.furnace` nhận `FurnacePlacementState` gồm committed ore/wood input, iron/pal output chờ nhận và progress timer hữu hạn trong một chu kỳ 5 giây. Timer dương không được tồn tại nếu input không đủ một batch. `is_smelting` được suy ra khi apply; Flam boost không serialize. Snapshot/apply lặp lại giữ nguyên input, output và progress thay vì trừ hoặc cộng item lần nữa.

## U1.12h cooking-pot subtype state

`building.cooking_pot` nhận `CookingPotPlacementState` gồm stable `recipe.cooking.*` và `remaining_seconds`. Active recipe bắt buộc thuộc `CookingRecipeCatalog` và timer nằm trong duration của recipe; idle bắt buộc recipe rỗng và timer 0. Apply resolve runtime recipe Dictionary từ catalog/legacy adapter, không serialize Dictionary hoặc trừ lại nguyên liệu đã commit.

## U1.12i compost-bin subtype state

`building.compost_bin` nhận `CompostBinPlacementState` gồm `organic_materials`, `ready_fertilizer_count` và `composting_timer`. Material bị khóa trong 0–10, output không âm, timer hữu hạn trong `[0,8)` và phải bằng 0 khi không còn material. Snapshot/apply lặp lại giữ nguyên input, output và progress thay vì chạy lại transaction.

## U1.12j ranch subtype state

`building.ranch` nhận `RanchPlacementState` gồm food, tối đa hai `{assignment_id, species_id}` và production timer. Owned assignment dùng `pet.*`; starter resident dùng `ranch.resident_starter`. ID trùng/localized, species không hỗ trợ, count âm và timer ngoài `[0,10)` fail closed. Runtime animal Node và behavior state được dựng lại từ assignment, không serialize.

## U1.12k farm-plot subtype state

`building.farm_plot` nhận `FarmPlotPlacementState` gồm stable crop/stage ID, growth timer, moisture, watered và fertilized flags. Stage/progress và moisture/watered phải coherent trước apply. EMPTY record không giữ stale crop/timer; apply không chạy growth/harvest side effect. Enum `CropStage`/`CropType` chỉ còn compatibility projection runtime.

## U1.12l altar subtype state

`building.altar` nhận idle hoặc active lifecycle. Active bắt buộc stable boss instance ID và HP 1–280; idle cấm stale boss ID/HP. Restore thay boss thuộc altar trước khi spawn đúng một actor với HP đã lưu, không gọi offering/summon presentation và suppress callback completion của actor bị thay.

## U1.12m turret subtype state

`building.turret` nhận `TurretPlacementState = {cooldown_remaining}` với giá trị hữu hạn trong `[0, 1.25]`. Snapshot/apply giữ nhịp bắn đã commit nhưng không serialize target Node, Callable, projectile hay tween. Restore chỉ gán scalar cooldown, không chạy targeting hoặc tạo phát bắn; field thừa và cooldown ngoài miền fail trước mutation.

## U1.12n chest durability

`ChestPlacementState` gồm inventory và `health` nguyên trong `[1, 250]`. DTO inventory-only từ U1.12f vẫn được đọc với health mặc định 250; snapshot mới luôn ghi health. Restore validate inventory/capacity/health trước commit, giữ scalar qua `_ready()` và không gọi damage/destruction flow. Health 0, vượt 250, sai type hoặc field thừa fail trước khi thay runtime chest.

## U1.12o furnace durability

`FurnacePlacementState` thêm `health` nguyên trong `[1, 300]`; state năm field từ U1.12g vẫn đọc với health mặc định 300. Snapshot mới ghi input/output/progress/health. Restore giữ health qua `_ready()` nhưng không chạy `_process()`, smelting transaction, damage hoặc destruction; health sai type/miền và field thừa fail trước runtime replacement.

## U1.12p cooking-pot durability

`CookingPotPlacementState` thêm `health` nguyên trong `[1, 200]`; state recipe/progress cũ vẫn đọc với health mặc định 200. Runtime cooking pot nhận durability foundation 200 HP theo pattern building hiện có. Restore resolve stable recipe trước commit, giữ health qua `_ready()` và không chạy cooking/finish/reward/destruction; invalid health fail trước runtime replacement.

## U1.12q ranch durability

`RanchPlacementState` thêm `health` nguyên trong `[1, 350]`; state ba field cũ vẫn đọc với health mặc định 350. Restore assignment/food/timer/health trước khi node vào tree; `_ready()` dựng đúng số animal presentation nhưng không chạy production, consume food, reward hoặc destruction. Invalid health fail trước runtime replacement.

## U1.12r altar structure durability

`AltarPlacementState` thêm `altar_health` nguyên trong `[1, 1000]`, độc lập với `boss_hp` tối đa 280. Lifecycle state ba field cũ vẫn đọc với altar health mặc định 1000. Restore giữ scalar qua `_ready()`, thay đúng một boss bằng suppression guard và không gọi offering/summon/completion/destruction. Invalid structure health fail trước khi thay altar hoặc boss runtime.

## U1.12s turret structure durability

`TurretPlacementState` gồm `cooldown_remaining` trong `[0, 1.25]` và `health` nguyên `[1, 350]`; DTO cooldown-only cũ mặc định 350. Restore giữ health qua `_ready()` và chỉ commit hai scalar, không target/fire/destruction. Target Node, projectile, Callable và tween không serialize; invalid health fail trước runtime replacement.
