# U1.9c — Creature defeat drop contract

## Phạm vi và ownership

Package này migrate đúng drop canary của `creature.flam`. `CreatureDropResolver` sở hữu quyết định deterministic; `WildCreature` chỉ tạo request bằng roll đã sinh, commit kết quả và spawn presentation node.

`CreatureDropRequest` chứa stable species/item ID, defeat/capture/duplicate guards, elite/alpha flags và hai count roll đã inject. Resolver không truy cập RNG, Node, SceneTree, animation hoặc inventory.

## Pure result

`CreatureDropResult.Status` gồm:

- `ACCEPTED`: request hợp lệ; trả primary item/count và bonus item/count.
- `INVALID_REQUEST`: ID sai domain hoặc count roll ngoài range hiện hữu.
- `NOT_DEFEATED`: creature còn sống.
- `CAPTURE_BLOCKED`: capture attempt/state/ownership đang hoạt động.
- `DUPLICATE`: drop của defeat này đã commit.

Balance được giữ nguyên:

| Variant | Primary | Bonus |
|---|---|---|
| Normal Flam | `item.pal_ore`, 1–2 node × count 1 | none |
| Elite/Alpha Flam | `item.pal_ore`, 3–5 node × count 1 | một `item.pal_ore` node, count 2–4 |

Roll được sinh trong actor bằng range cũ rồi inject vào request. Cùng request luôn cho cùng result.

## Actor commit invariant

- `defeat_committed` phải có trước khi resolver chấp nhận.
- `defeat_drops_committed` được set trước spawn; callback lặp không tạo thêm drop.
- Actor kiểm tra result species và primary item khớp authority hiện tại trước commit.
- Spawned `DroppedItem` nhận cả stable `item_id` và legacy display/inventory key qua adapter.
- Capture thành công không đi qua defeat drop; capture đang hoạt động fail closed trong resolver.

## Writer audit còn lại

| Writer | Hiện trạng | Package sau |
|---|---|---|
| Flam primary/elite drop | pure result + atomic actor commit | U1.9c verified |
| Slime/Mushroom/Beast/Dragon drop | legacy localized `drop_item` và actor spawn | migrate sau khi có typed species definitions |
| EXP reward trong `die()` | legacy level/elite/alpha formula | progression package |
| Predator/prey target + FLEE/grazing | legacy behavior profile projection và actor conditions | ecology ownership package |
| Burn tick defeat path | direct legacy status writer | status/combat package |

## Compatibility, asset và rollback

- Không đổi quantity/probability, EXP, collision, capture outcome, scene hierarchy hoặc save schema.
- Không thêm/sửa asset; provenance status không đổi.
- Rollback bằng revert U1.9c; không cần data/save migration.
