# U1.3 — Recipe, Building và Crop definitions

## Phạm vi và hiện trạng được audit

U1.3 tạo catalog typed cho ba canary đang tồn tại trong prototype mà không thay quyền sở hữu runtime:

| Domain | Canary stable ID | Prototype hiện tại | Trạng thái runtime U1.3 |
|---|---|---|---|
| Recipe | `recipe.pal_sphere.basic` | `player.gd` recipe `regular_sphere`: 1 Quặng Pal + 1 Gỗ → 2 Cầu Thu Phục | Typed mirror; dictionary Player vẫn authoritative |
| Building | `building.workbench` | `building_workbench.tscn/.gd`, 200 HP, mở crafting menu | Typed mirror; scene/script vẫn authoritative |
| Crop | `crop.berry` | `ResourceNode.CropType.BERRY`, grow ready ở 10 giây, yield 3–5 | Typed mirror; enum và logic ResourceNode vẫn authoritative |

Các item hỗ trợ `item.pal_ore`, `item.pal_sphere.basic`, `item.berry_seed`, `item.berry` được thêm để cross-reference resolve được. U1.7b bổ sung `item.pal_sphere.mega/giga`; ba sphere ID đã map qua `LegacyItemAdapter` vào key cũ, còn backing inventory vẫn là dictionary legacy duy nhất. Các item khác tiếp tục migrate dần theo domain package.

## Schema

### ItemAmount

- `item_id: StringName`: ID hợp lệ thuộc domain `item`.
- `quantity: int`: lớn hơn 0.
- Đây là value Resource nhúng trong recipe/building, không có identity riêng và không đặt thành file độc lập trong definition tree.

### RecipeDefinition

- `content_id`: domain `recipe`.
- `inputs: Array[ItemAmount]`: ít nhất một input, không null, không trùng item.
- `output: ItemAmount`: bắt buộc.
- `station_id`: stable ID thuộc domain `building`.
- `craft_time_seconds > 0`; `unlock_level >= 0`.

Canary sphere dùng `item.wood ×1`, `item.pal_ore ×1`, output `item.pal_sphere.basic ×2`, station `building.workbench`, thời gian 2 giây và unlock level 1.

### BuildingDefinition

- `content_id`: domain `building`.
- `scene: PackedScene`: bắt buộc; scene path không phải identity.
- `max_health > 0`.
- `build_cost`: ItemAmount hợp lệ, không trùng item.
- `supported_recipe_ids`: ID domain `recipe`, không trùng.
- `tags`: capability/query, không phải text UI.

Canary workbench trỏ tới scene prototype, 200 HP, cost catalog `item.wood ×10` và support recipe sphere. Cost này chưa được runtime placement tiêu thụ.

### CropDefinition

- `content_id`: domain `crop`.
- `seed_item_id`, `harvest_item_id`: stable ID domain `item`.
- `growth_time_seconds > 0`.
- `harvest_yield_min > 0`; max không nhỏ hơn min.

Canary berry dùng `item.berry_seed`, output `item.berry`, growth 10 giây, yield 3–5. Water/fertilizer multiplier vẫn thuộc prototype và chưa đi vào schema U1.3.

## Cross-reference validation

`ContentRegistry.load_directory()` thực hiện hai pass:

1. Load theo path đã sort, validate từng definition và reject duplicate ID.
2. Duyệt definition theo stable ID đã sort, lấy `get_referenced_content_ids()` và reject mọi ID hợp lệ nhưng không tồn tại trong catalog.

Reference validation chạy sau khi toàn bộ file đã được register nên recipe ↔ building có thể tham chiếu hai chiều mà không phụ thuộc thứ tự file. Invalid grammar/domain được subtype báo; missing target được registry báo với source content ID và resource path.

`validate_references()` là public để test catalog dựng trong bộ nhớ. Caller chỉ gọi sau khi register xong; registry không tự xóa lỗi cũ ngoài `clear()`.

## Compatibility và ownership

- Definition là immutable catalog data; Node runtime không mutate Resource.
- U1.3 không bootstrap registry thành autoload và không thay dictionary/enum prototype.
- Không có runtime store thứ hai. `.tres` là typed mirror phục vụ validation và migration package sau.
- U1.2 wood adapter giữ nguyên. Bốn item mới chưa có mapping để ngăn producer dùng stable API trước khi consumer/storage sẵn sàng.
- Scene/icon là reference presentation đã có; toàn bộ asset vẫn `QUARANTINE/UNKNOWN`.
- Không có save format nên không cần migration. Stable IDs mới phải được giữ hoặc có migration khi save v1 bắt đầu sử dụng.

## Validation và rollback

`tools/validate_content.gd` kiểm tra domain/range/required field, duplicate registry ID, missing station/input/output reference, đúng tám definition và field/link của ba canary. `tools/check_project.ps1` tiếp tục chạy documentation, asset, editor load, content validation, item migration và main smoke.

Rollback U1.3 là revert commit package; runtime chưa đọc definition mới nên không cần chuyển dữ liệu ngược.

## Boundary tiếp theo

U1.4 tạo inventory transaction theo stable ID với add/remove/capacity/transfer atomic. Migration đầu tiên phải chuyển pickup và chest cho tập item nhỏ, cung cấp compatibility view cho HUD/recipe legacy và có test rollback khi capacity không đủ. Không dùng typed mirror U1.3 làm runtime authority trước khi bootstrap/ownership registry được chốt trong U1.4.
