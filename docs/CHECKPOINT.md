# Checkpoint triển khai Paloria 3.0

## U1.7b — stable sphere selection và inventory/spawn transaction

Trạng thái: `VERIFIED` ngày 2026-10-04; package branch `work/u1.7b-sphere-transaction`.

### Mục tiêu và invariant

- Chọn sphere bằng stable item ID với thứ tự cố định Giga → Mega → Basic.
- Validate toàn bộ điều kiện có thể thất bại trước khi trừ inventory.
- Một lần launch hợp lệ chỉ trừ đúng một sphere đã chọn; cooldown/build/unknown ID không làm đổi inventory.
- Projectile và missed drop giữ stable item ID; localized/legacy name chỉ là compatibility adapter.
- Không tạo inventory backing store thứ hai và không đổi deterministic capture resolver của U1.7a.

### Kết quả đã triển khai

- Thêm pure `CaptureSphereSelector` và `CaptureSphereSelectionResult` với ba ID:
  - `item.pal_sphere.basic` — multiplier `1.0`.
  - `item.pal_sphere.mega` — multiplier `2.0`.
  - `item.pal_sphere.giga` — multiplier `4.0`.
- Bổ sung typed `ItemDefinition` cho Mega/Giga; content registry hiện có 10 definition.
- Mở rộng `LegacyItemAdapter` để ba stable ID vẫn đọc/ghi cùng dictionary inventory legacy.
- `Player.throw_pal_sphere()` thực hiện select → validate scene/configuration → atomic remove → add/launch → feedback và trả `bool`.
- `Sphere` được cấu hình bằng stable ID, từ chối ID/multiplier không khớp, và truyền ID đó sang missed `DroppedItem`.
- `DroppedItem` chọn visual cho cả ba sphere bằng stable ID.
- Contract/data/module/gameplay/roadmap đã được cập nhật theo implementation.

### File và API chính

- `systems/capture/capture_sphere_selector.gd`: pure priority/multiplier lookup.
- `systems/capture/capture_sphere_selection_result.gd`: result `OK | NONE_AVAILABLE`.
- `scripts/player.gd`: `throw_pal_sphere() -> bool`, `select_capture_sphere()`, `spend_capture_sphere(selection)`.
- `scripts/sphere.gd`: `configure_capture_sphere(item_id, multiplier) -> bool`, `create_missed_drop()`.
- `data/definitions/items/pal_sphere_{basic,mega,giga}.tres` và `data/legacy_item_adapter.gd`.
- Regression mở rộng trong `tools/validate_capture.gd`, `validate_content.gd`, `validate_item_migration.gd`.

Contract đầy đủ: `architecture/CAPTURE_CONTRACT.md` và `architecture/INVENTORY_TRANSACTIONS.md`.

### Validation

`tools/check_project.ps1` đạt ngày 2026-10-04:

- Documentation: 26 required file, 28 Markdown file.
- Asset gate: 166/166 asset được phân loại; provenance/action không đổi.
- Headless editor load, content, inventory migration, combat, needs, locomotion, Player action, capture và main-scene smoke đều đạt.
- Capture regression gồm deterministic resolver U1.7a và selection/transaction/projectile/drop stable ID U1.7b.
- Capture được lặp 15 lần sau khi cô lập headless audio; không còn `ObjectDB`/resource leak.
- Log: `build/checks/capture-validation.log` và `build/checks/headless-smoke.log`.

### Compatibility, save, asset và giới hạn

- Save/data breaking change: none. Dictionary inventory legacy vẫn là backing store duy nhất; adapter ánh xạ stable ID hai chiều.
- Asset/provenance: không thêm asset; typed definition chỉ tham chiếu asset hiện có.
- Add projectile là thao tác đồng bộ ngay sau inventory commit. Các failure point dự kiến đều đã được validate trước commit; chưa có rollback cho exception engine ngoài contract.
- Craft output vẫn ghi legacy key trực tiếp, nhưng stable reader quan sát cùng backing store qua adapter.
- Manual editor test còn cần cho quỹ đạo ném, hit/miss, visual của ba sphere và pickup lại missed drop.
- `player.gd` tăng từ 1076 lên 1090 dòng do compatibility boundary; việc tách roster/summon tiếp tục ở các package sau.
- Rollback: revert commit U1.7b; save cũ không cần migration.

### Gói tiếp theo

U1.7c chỉ xử lý roster ownership commit:

- Stable species identity tại capture boundary.
- Pure ownership/admission request-result và deterministic trait/rarity input.
- Player commit trả kết quả; WildCreature chỉ despawn khi ownership được chấp nhận.
- Duplicate/re-entry guard và regression reject-without-despawn.
- Không làm summon Node lifecycle, command UI hoặc save roster; các phần đó thuộc U1.10/G06.

Lệnh đầu tiên: chạy `tools/check_project.ps1`, sau đó audit `Player.on_pet_captured`, `WildCreature.capture_succeeded`, `pet_party` và `swap_active_pet` trước khi thiết kế contract.

## Lịch sử

- U1.7a: deterministic capture request/result và injected roll.
- U1.6: Player needs, locomotion và action input boundaries.
- U1.5: deterministic combat request/result.
- U1.4: inventory transaction + chest capacity.
- U1.3: typed domain definitions.
- U1.2: stable wood adapter.
- U1.1: stable IDs/registry.
