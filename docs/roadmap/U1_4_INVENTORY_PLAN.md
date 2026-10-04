# U1.4 — kế hoạch inventory transaction

## Mục tiêu package

Tạo boundary transaction theo stable item ID cho add, remove và transfer; migrate pickup và chest mà vẫn giữ một nguồn dữ liệu trong lúc recipe, farm, HUD và quest còn truy cập dictionary legacy.

U1.4 không chuyển toàn bộ crafting/farming, không thêm equipment/weight/save UI và không mở rộng content catalog ngoài item thực sự cần cho pickup/chest.

## Hiện trạng phải bảo toàn

- `Player.inventory` và `BuildingChest.stored_items` là dictionary keyed bằng text tiếng Việt.
- Nhiều consumer đọc và ghi trực tiếp; thay storage ngay sẽ làm chúng lệch state.
- U1.2 đã cung cấp stable add/read cho `item.wood` trên chính dictionary Player.
- U1.3 có catalog item wood, pal ore, basic sphere, berry seed và berry nhưng bốn item mới chưa có legacy mapping/runtime stable API.
- Drop phải ở lại world nếu add thất bại.

## Thiết kế dự kiến

### InventoryTransaction

Pure service nhận dictionary backing store được inject và mapping stable ID → legacy key. Không giữ bản sao inventory.

Public operation dự kiến:

- `get_count(item_id)`.
- `can_add(item_id, amount)` và `add(item_id, amount)`.
- `can_remove(item_id, amount)` và `remove(item_id, amount)`.
- `transfer_to(target, item_id, amount)` kiểm tra cả hai đầu trước rồi commit; thất bại không đổi đầu nào.
- Batch plan/commit chỉ thêm nếu chest cần bảo đảm all-or-nothing; không tạo abstraction chưa có consumer.

Result cần có status enum ổn định như `OK`, `INVALID_ITEM`, `INVALID_AMOUNT`, `INSUFFICIENT_ITEMS`, `CAPACITY_EXCEEDED`; kèm requested/applied amount. Presentation không quyết định kết quả.

### Capacity policy

Chọn và ghi rõ một policy trước khi code:

- Giới hạn slot: mỗi item ID chiếm `ceil(count/max_stack)` slot, lấy `max_stack` từ `ItemDefinition`; hoặc
- U1.4a chưa bật capacity, nhưng API nhận policy vô hạn rõ ràng và regression xác nhận. Capacity hữu hạn phải xuất hiện trước khi tuyên bố G03 acceptance “inventory đầy”.

Registry/catalog dependency phải được inject hoặc bootstrap bởi owner rõ ràng. Domain service không tự load file hay truy cập SceneTree.

### Compatibility

- Backing dictionary legacy là nguồn sự thật trong U1.4; stable transaction resolve key qua adapter rồi mutate dictionary đó.
- Mở rộng mapping chỉ cho item có definition và runtime consumer được migrate cùng package.
- Direct legacy mutation còn lại phải được liệt kê. Không tạo dictionary stable song song hoặc đồng bộ hai chiều bằng frame polling.
- Player/chest phát đúng một notification sau transaction thành công; transaction thất bại không phát HUD/quest/audio success.

## Thứ tự triển khai

1. Audit mọi direct mutation của Player/chest và khóa scope item/operation.
2. Viết pure transaction + result và regression add/remove/transfer/rollback.
3. Mở rộng mapping được chọn; test stable và legacy read cùng state.
4. Migrate `DroppedItem.collect()` và `BuildingChest` qua transaction boundary.
5. Giữ API legacy làm adapter cho consumer chưa migrate.
6. Chạy main smoke và test interaction headless riêng cho chest transfer.
7. Đồng bộ module, G03/G10/G11, data contract, checkpoint và save impact.

## Acceptance gate

- Add/remove reject ID/amount không hợp lệ mà không mutate.
- Remove thiếu item không trừ một phần.
- Transfer thành công bảo toàn tổng lượng; transfer thất bại giữ nguyên cả source và target.
- Pickup thất bại không despawn.
- Chest deposit/withdraw không duplicate hoặc mất item; notification chỉ sau commit.
- Legacy HUD/recipe thấy đúng số lượng sau stable transaction.
- Full `tools/check_project.ps1` sạch; không thêm asset và không đổi save format.

## Tách package nếu scope tăng

Nếu capacity + chest batch + catalog bootstrap không thể hoàn tất trong 0,5–2 ngày, chia:

- **U1.4a:** pure transaction trên legacy backing store, Player/drop integration.
- **U1.4b:** chest atomic transfer và capacity policy.

Không chuyển sang stable backing store cho tới khi các direct writer recipe/farm/building đã có transaction boundary hoặc compatibility proxy có test đầy đủ.
