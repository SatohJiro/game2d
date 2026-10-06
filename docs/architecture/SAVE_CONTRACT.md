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

U1.11 foundation kết thúc ở explicit API có kiểm thử. Chưa có autosave, slot UI, pause/transaction scheduling, world entity delta, base/building/crop/quest DTO hoặc checksum. Pet rarity/trait/inactive stance được bổ sung ở U1.12c.

## U1.12b runtime inventory identity closure

`RuntimeInventoryManifest` phân nhóm toàn bộ 25 localized key reachable ở runtime. Mười bốn identity còn thiếu đã có stable `item.*`, typed definition và reverse mapping; snapshot Player được regression riêng cho core/crafting/farming/ranch/cooking nên các output hợp lệ không còn chặn toàn save bằng `UNMAPPED_ITEM`. Adapter vẫn fail closed với key ngoài tập admit và vẫn dùng đúng một legacy backing dictionary. Save v1 shape/economy không đổi.

## U1.12c pet metadata persistence

Mỗi `pets[]` entry bắt buộc có `rarity_id`, `trait_id`, `stance_id` thuộc allowlist stable. Snapshot không ghi badge/trait localized; apply dựng lại presentation bằng `PetMetadataCatalog`. Active actor là authority stance khi snapshot, roster là authority cho pet inactive; Player ghi stance về roster trước khi replace và áp stance roster khi summon.

Đây là thay đổi shape của Save v1 nhưng không tăng `schema_version`: dự án chưa phát hành và chưa có save tương thích được cam kết. Vì vậy migration table vẫn không có pre-v1 route; snapshot thiếu field mới fail validation thay vì tự đoán metadata. Sau bản phát hành đầu tiên, mọi thay đổi shape tiếp theo phải tăng version và có migration step.

## U1.12d base/quest progression

Envelope thêm `base = {base_level, active_quest_id, claimed_quest_ids}`. `BaseProgressState` bắt buộc claimed IDs là prefix catalog, active quest là phần tử kế tiếp và level khớp reward đã claim. Snapshot đọc typed boundary của BaseManager; apply validate/resolve trước mutation và không gọi reward flow. Non-default base state thiếu runtime owner fail closed; Player scene độc lập có thể dùng pristine default.

Shape v1 tiếp tục được cập nhật tại pre-release nên không tăng version; không có migration cho save cũ chưa phát hành. Localized quest title và index không được chấp nhận làm identity.
