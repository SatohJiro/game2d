# Checkpoint triển khai Paloria 3.0

## U1.2 — adapter pickup/inventory cho `item.wood`

Trạng thái: `VERIFIED` ngày 2026-10-04; package được tích hợp từ branch `work/u1.2-item-adapter` vào `main` bằng fast-forward.

### Mục tiêu và invariant

- Chuyển đúng một vertical slice `resource tree → dropped wood → Player inventory` sang stable ID `item.wood`.
- Giữ `Player.inventory["Gỗ"]` là nguồn sự thật duy nhất để recipe, chest, HUD và quest cũ tiếp tục hoạt động.
- Stable add/read và legacy add phải nhìn thấy cùng số lượng; không tạo key `item.wood` song song.
- Pickup chỉ biến mất sau khi inventory xác nhận add thành công; invalid count/unknown ID thất bại mà không mutate.
- Không đổi balance, save format, asset path, asset byte hoặc license status.

### Code và data flow

- `data/legacy_item_adapter.gd`: mapping hai chiều `Gỗ` ↔ `item.wood`, stable read/add trên dictionary legacy và fail-closed cho ID chưa map.
- `scripts/resource_node.gd`: gắn stable ID đã resolve lên drop; item chưa migrate vẫn có `item_id` rỗng.
- `scripts/dropped_item.gd`: ưu tiên stable pickup API, fallback legacy cho item chưa migrate, chỉ free khi add thành công.
- `scripts/player.gd`: `add_item_by_id`, `get_item_count_by_id`; `add_item` legacy route gỗ qua cùng boundary và trả `bool`.
- `tools/validate_item_migration.gd`: regression adapter, drop scene và Player thật sau khi bootstrap `main.tscn`.
- `tools/check_project.ps1`: thêm item migration gate giữa content validation và main smoke.

Luồng và ownership chi tiết nằm trong `docs/architecture/INVENTORY_MIGRATION.md`.

### Tài liệu đã đồng bộ

- `docs/architecture/INVENTORY_MIGRATION.md`: API, invariant, compatibility, failure policy, rollback và kế hoạch U1.4.
- `docs/architecture/DATA_CONTRACTS.md`, `MODULES.md`: trạng thái stable boundary và nguồn dữ liệu hiện tại.
- `docs/gameplay/FEATURES.md`: G03 phản ánh pickup gỗ đã migrate.
- Roadmap, major update plan, index, documentation gate và prompt cho model tiếp theo đã chuyển sang U1.3.

### Validation

Lệnh:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1
```

Kết quả ngày 2026-10-04:

- Documentation: 22 required files, 20 Markdown files, không broken relative link.
- Asset integrity/action: 166/166; 0 verified, 166 quarantine/unknown; 69 runtime P0.
- Godot 4.7.2 editor-load: exit 0, log sạch.
- Content registry: `item.wood` và registry contract pass.
- Item migration: mapping, invalid input, single source of truth, drop resolution và Player add/read pass.
- Main scene smoke 120 frame: exit 0, log sạch.
- Log: `build/checks/headless-editor.log`, `content-validation.log`, `item-migration-validation.log`, `headless-smoke.log`.

### Compatibility, asset và phần chưa làm

- Save/data breaking change: không; dự án chưa có save system và storage vẫn là dictionary legacy.
- `add_item` đổi return type từ `void` sang `bool`; call site cũ có thể bỏ qua kết quả nên vẫn tương thích GDScript, còn drop mới dùng kết quả để quyết định despawn.
- Chỉ `item.wood` được map. Stone, ore, crop, food, building cost, recipe, chest và HUD vẫn dùng tên tiếng Việt.
- Chưa có capacity, max-stack enforcement, remove/transfer hoặc atomic multi-item transaction; thuộc U1.4.
- Registry chưa là autoload; adapter dùng stable ID contract nhưng không lookup definition lúc pickup.
- Không thêm/tải/sửa asset. `assets/items/wood.png` và toàn bộ 166 asset vẫn `QUARANTINE/UNKNOWN`; 69 runtime asset P0 cần xác minh hoặc thay trước release.
- Visual/manual playtest chưa thực hiện trong package headless; hành vi được bao phủ bằng integration regression và 120-frame smoke.

### Gói tiếp theo

U1.3 tạo ba typed canary definition có liên kết chéo tối thiểu: một recipe, `building.workbench` và một crop. Package phải thêm validation cho positive quantities/time và missing referenced ID, nhưng chưa chuyển toàn bộ catalog hoặc inventory storage. Giữ adapter U1.2; chọn đúng một runtime read boundary nếu việc nối definition không làm package vượt ba module.

## Lịch sử

- U1.1: stable content IDs, `ItemDefinition`, registry và content validator; `VERIFIED` ngày 2026-10-04.
- U0.4: action/priority/owner cho 166 asset; `VERIFIED` ngày 2026-10-04.
- U0.3: Git baseline/tag và restore worktree test; `VERIFIED` ngày 2026-10-04.
- U0.2: asset manifest và documentation gates; `VERIFIED` ngày 2026-10-04.
- U0.1: parse/audio lifecycle và Godot headless gate; `VERIFIED` ngày 2026-10-04.
