# U1.4 — Inventory transaction contract

## Trạng thái U1.4a

U1.4a tạo transaction thuần theo stable ID trên dictionary legacy được inject. Transaction không giữ bản sao; `Player.inventory["Gỗ"]` vẫn là nguồn sự thật duy nhất. Capacity policy hiện là `UNLIMITED`; finite slots/max-stack thuộc U1.4b.

## Public types

### InventoryTransactionResult

Status:

- `OK`: commit đủ requested amount.
- `INVALID_ITEM`: ID sai grammar hoặc chưa có legacy mapping.
- `INVALID_AMOUNT`: amount không dương.
- `INSUFFICIENT_ITEMS`: source không đủ; không trừ một phần.
- `CAPACITY_EXCEEDED`: dành cho finite policy U1.4b, chưa phát sinh với `UNLIMITED`.

Result mang `item_id`, `requested_amount`, `applied_amount`; `is_success()` chỉ true với `OK`.

### InventoryTransaction

- Constructor nhận backing `Dictionary` và capacity policy; không truy cập SceneTree, registry, HUD hoặc audio.
- `get_count`, `can_add`, `add`, `can_remove`, `remove` dùng stable ID.
- `transfer_to` validate source và target trước commit. Nếu target write bất ngờ thất bại, source được restore về giá trị trước transaction.
- U1.4a chỉ có `CapacityPolicy.UNLIMITED`, được expose rõ qua `get_capacity_policy()`.

## Player/drop integration

- `Player.add_item_by_id` và `get_item_count_by_id` đã route qua transaction.
- `Player.remove_item_by_id` là stable remove boundary mới.
- Player chỉ gọi `_on_inventory_changed()` sau commit thành công; failure không phát audio/HUD/quest success.
- `DroppedItem.collect()` tiếp tục dựa vào bool adapter của Player; rejected stable item không despawn.
- `Player.add_item(name, count)` vẫn là compatibility boundary. Wood route qua transaction; item chưa map dùng legacy write như trước.

## Direct writer audit còn legacy

| Owner | Mutation | Package xử lý |
|---|---|---|
| `building_chest.gd` | deposit/withdraw trực tiếp Player + chest dictionary | U1.4b |
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

U1.4a chỉ support `item.wood` ↔ `Gỗ`. Các definition U1.3 chưa được map vì chưa có runtime consumer trong scope. `LegacyItemAdapter.set_count` cho phép transaction commit/rollback và reject count âm.

Unlimited capacity là lựa chọn có chủ ý để U1.4a không bootstrap registry/global service vội. Vì vậy acceptance “inventory đầy” của G03 chưa đạt và phải được test trong U1.4b trước khi đánh dấu inventory transaction hoàn chỉnh.

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

## U1.4b

Migrate chest bằng transaction atomic, mở mapping đúng item chest có typed definition, và chọn finite slot/max-stack policy được inject từ catalog. Nếu bootstrap registry cần owner mới, ghi contract lifetime rõ và test missing definition/capacity rollback.
