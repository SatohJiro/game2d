# U1.4 — Inventory transaction contract

## Trạng thái U1.4

U1.4a tạo transaction thuần theo stable ID trên dictionary legacy được inject. U1.4b bổ sung finite stack slots và chest batch atomic. Transaction không giữ bản sao; dictionary legacy vẫn là nguồn sự thật duy nhất.

## Public types

### InventoryTransactionResult

Status:

- `OK`: commit đủ requested amount.
- `INVALID_ITEM`: ID sai grammar hoặc chưa có legacy mapping.
- `INVALID_AMOUNT`: amount không dương.
- `INSUFFICIENT_ITEMS`: source không đủ; không trừ một phần.
- `CAPACITY_EXCEEDED`: batch/add làm vượt số slot.
- `MISSING_DEFINITION`: finite policy thiếu max-stack được inject cho item.

Result mang `item_id`, `requested_amount`, `applied_amount`; `is_success()` chỉ true với `OK`.

### InventoryTransaction

- Constructor nhận backing `Dictionary` và capacity policy; không truy cập SceneTree, registry, HUD hoặc audio.
- `get_count`, `can_add`, `add`, `can_remove`, `remove` dùng stable ID.
- `transfer_to` validate source và target trước commit. Nếu target write bất ngờ thất bại, source được restore về giá trị trước transaction.
- `UNLIMITED` dùng cho Player trong giai đoạn chuyển tiếp; `STACK_SLOTS` dùng cho chest.
- Finite usage là tổng `ceil(count / max_stack)` trên item đã map. Max-stack lookup và max slots do owner inject; domain service không load Resource.
- `transfer_batch_to` mô phỏng toàn batch trên shadow stores trước commit; failure không chuyển một phần.

## Player/drop integration

- `Player.add_item_by_id` và `get_item_count_by_id` đã route qua transaction.
- `Player.remove_item_by_id` là stable remove boundary mới.
- Player chỉ gọi `_on_inventory_changed()` sau commit thành công; failure không phát audio/HUD/quest success.
- `DroppedItem.collect()` tiếp tục dựa vào bool adapter của Player; rejected stable item không despawn.
- `Player.add_item(name, count)` vẫn là compatibility boundary. Wood route qua transaction; item chưa map dùng legacy write như trước.

## Direct writer audit còn legacy

| Owner | Mutation | Package xử lý |
|---|---|---|
| `building_chest.gd` | wood/pal ore/berry đã atomic; stone/ingot còn legacy, không tham gia quick batch | package catalog/storage sau |
| `player.gd` crafting/capture/food | sphere, recipe input/output, consumable | U1.5+ hoặc package craft/needs riêng |
| `building_furnace.gd` | ore/wood consume, ingot output | U5 processing boundary |
| `building_cooking_pot.gd` | recipe cost/output | U5 processing boundary |
| `building_compost_bin.gd` | feedstock consume/fertilizer output | U5 processing boundary |
| `resource_node.gd` | seed/fertilizer consume | farming transaction package |
| `building_ranch.gd` | feed consume | ranch transaction package |
| `building_altar.gd` | ingot/berry consume | progression transaction package |
| `base_manager.gd`, `hud.gd` | read-only legacy dictionary | compatibility view until consumer migration |
| `pet.gd` | gọi Player legacy add | giữ tương thích; stable item migration sau yield catalog |

Không tạo stable dictionary song song và không đồng bộ state bằng `_process`.

## Mapping và capacity

Mapping runtime hiện support `item.wood`, `item.pal_ore`, `item.berry`. Chest inject max-stack từ ba `ItemDefinition` preload và có 12 slot mặc định. Stone/iron/pal ingot chưa có definition nên không được batch mới mutate.

Player vẫn unlimited để không thay balance. Chest finite capacity đã có regression exact stack, mở stack, full slots và missing definition fail-closed.

## Invariant và regression

- Invalid item/amount không mutate.
- Insufficient remove không mutate.
- Transfer thành công bảo toàn tổng lượng.
- Transfer thất bại giữ nguyên source/target.
- Stable và legacy read quan sát cùng state.
- Notification chỉ sau successful Player commit.
- Rejected pickup ở lại world.

`tools/validate_item_migration.gd` bao phủ các invariant trên cùng Player thật được bootstrap từ main scene. Full gate tiếp tục chạy content validation và 120-frame smoke.

## Save, asset và rollback

Không có save schema và không thêm/sửa asset. Rollback là revert commit U1.4a; backing dictionary không đổi định dạng.

## Sau U1.4

Các direct writer còn lại được migrate cùng domain owner tương ứng. Stable backing store chỉ thay legacy dictionary sau khi crafting/farming/needs không còn direct write và save migration đã có.
