# Chuyển tiếp inventory từ key hiển thị sang stable ID

## Phạm vi hiện tại

U1.2 chuyển vertical slice `chặt cây → drop gỗ → player inventory` sang API `item.wood`. U1.4a đã đặt stable add/read/remove trên `InventoryTransaction`; recipe, chest, HUD, quest và phần lớn item vẫn đọc dictionary bằng tên tiếng Việt. Adapter duy trì đúng một nguồn dữ liệu.

Không có thay đổi save format trong package này. Dự án chưa có save system.

## Luồng runtime

```text
ResourceNode.spawn_dropped_item("Gỗ", count)
  → gắn DroppedItem.item_id = item.wood
  → DroppedItem.collect()
  → Player.add_item_by_id(item.wood, count)
  → LegacyItemAdapter.add(...)
  → inventory["Gỗ"] được cập nhật
  → HUD/quest/recipe legacy nhìn thấy cùng số lượng
```

Nếu drop chưa được migrate, `item_id` để rỗng và `DroppedItem` gọi `Player.add_item(item_name, count)`. Vì vậy đá, quặng, nông sản và các loot cũ tiếp tục hoạt động. Nếu drop cung cấp stable ID hợp lệ nhưng adapter chưa có mapping, pickup thất bại và drop ở lại world; hệ thống không âm thầm ghi một key stable song song.

## Public API và invariant

| API | Kết quả | Quy tắc |
|---|---|---|
| `LegacyItemAdapter.to_content_id(legacy_or_id)` | `StringName` hoặc rỗng | Chuyển key đã map; chấp nhận stable ID đúng grammar để định tuyến, không khẳng định item đã được support |
| `LegacyItemAdapter.to_legacy_key(id)` | `String` hoặc rỗng | Chỉ trả key đã map |
| `LegacyItemAdapter.get_count(inventory, id)` | số lượng không âm | Unknown ID trả `0`, không mutate |
| `LegacyItemAdapter.add(inventory, id, amount)` | `bool` | Reject amount `<= 0` và ID chưa map |
| `Player.add_item(name, count)` | `bool` | Giữ tương thích legacy; `Gỗ` được route qua stable API |
| `Player.add_item_by_id(id, count)` | `bool` | Stable add qua transaction |
| `Player.get_item_count_by_id(id)` | `int` | Boundary đọc stable ID trong giai đoạn chuyển tiếp |
| `Player.remove_item_by_id(id, count)` | `bool` | Stable atomic remove; thiếu item không trừ dở |
| `DroppedItem.get_resolved_item_id()` | `StringName` hoặc rỗng | `item_id` hợp lệ được ưu tiên, sau đó mới map `item_name` |

Invariant U1.2:

- Dictionary `Player.inventory` vẫn là nguồn sự thật duy nhất.
- Với gỗ, dictionary chỉ chứa key `Gỗ`; không tạo key `item.wood` song song.
- Mutation thất bại không xóa drop khỏi world.
- Amount rỗng/âm/0 và stable ID chưa map không làm đổi inventory.
- Consumer legacy tiếp tục thấy thay đổi do stable API tạo ra.

## Ownership và giới hạn

- `LegacyItemAdapter` sở hữu mapping tạm giữa stable ID và key legacy.
- `Player` sở hữu dictionary và thông báo HUD/quest sau mutation thành công.
- `DroppedItem` chỉ định tuyến pickup và chỉ tự hủy khi inventory xác nhận thành công.
- `ResourceNode` chỉ gắn stable ID khi tạo drop; yield table vẫn là legacy và sẽ được data hóa ở package sau.
- Adapter chỉ map key; transaction sở hữu add/remove/transfer. Capacity/max stack và chest batch thuộc U1.4b.

Các consumer còn dùng key legacy trực tiếp gồm recipe/crafting, chest/storage, farming, building cost, quest và HUD. Không thêm mapping mới nếu chưa có `ItemDefinition`, regression và một producer/consumer cụ thể được migrate cùng package.

## Kiểm thử và rollback

`tools/validate_item_migration.gd` kiểm tra mapping hai chiều, single source of truth, invalid input, scene drop resolution và Player thật được instantiate từ `main.tscn`. Test tách player khỏi presentation sau bootstrap để API inventory không phụ thuộc audio/HUD.

`tools/check_project.ps1` chạy test này sau content registry validation và trước main smoke. Log nằm tại `build/checks/item-migration-validation.log`; mọi `SCRIPT ERROR`, `ERROR`, parse/resource failure đều làm gate thất bại.

Rollback package U1.2 là revert commit của package. Không cần data migration vì chưa có save và dictionary runtime vẫn giữ định dạng cũ.

## Bước chuyển tiếp tiếp theo

U1.4a đã tạo transaction trên backing store legacy. U1.4b tiếp tục chest/capacity; stable backing store chỉ được xem xét sau khi direct writer đã có boundary.
