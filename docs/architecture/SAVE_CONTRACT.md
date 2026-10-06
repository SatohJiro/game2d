# U1.11a–b — Save v1 schema and runtime snapshot

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
- Pets: party dictionary được project về instance/species/level/EXP; active CompanionPet cung cấp stance hiện tại, pet không active mặc định `pet.stance.auto_work` vì roster hiện chưa giữ stance mutable.
- World: package chỉ inject `day_time`/clock scalar từ caller; entity delta vẫn rỗng.
- Snapshot/result deep-copy dữ liệu. Mutation snapshot sau đó không đổi inventory hoặc roster runtime.

U1.11b admit `item.stone` và `item.iron_ingot` cùng definitions/mapping để toàn bộ inventory mặc định project được. Food/fertilizer/crop key legacy chỉ phát sinh ở các loop khác chưa được admit; nếu tồn tại, snapshot fail closed cho tới package migration tương ứng, không silently drop.
