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

Runtime capture sphere IDs đã được admit ở U1.7b: `item.pal_sphere.basic`, `item.pal_sphere.mega`, `item.pal_sphere.giga`. Cả ba map vào backing dictionary legacy qua `LegacyItemAdapter`; stable ID là identity cho selection/projectile/drop, text cũ chỉ là compatibility storage/display.

U1.7c dành năm stable species ID `creature.flam`, `creature.slime`, `creature.mushroom`, `creature.beast`, `creature.dragon`. `LegacySpeciesAdapter` map index hiện hữu sang ID và deep-copy snapshot tại capture boundary. Đây là compatibility mapping; chưa có typed `CreatureDefinition` hoặc registry entry.

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
