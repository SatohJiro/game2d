# Checkpoint triển khai Paloria 3.0

## U1.4a — pure inventory transaction và Player/drop

Trạng thái: `VERIFIED` ngày 2026-10-04; package sẽ được fast-forward từ `work/u1.4a-inventory-transaction` vào `main`.

### Mục tiêu và invariant

- Stable add/remove/transfer dùng một backing dictionary được inject; không có store song song.
- Invalid ID/amount và insufficient remove không mutate.
- Transfer validate hai đầu trước commit, bảo toàn tổng; failure giữ nguyên source/target.
- Player chỉ phát notification sau commit thành công.
- Pickup bị inventory từ chối vẫn ở world.
- Capacity policy U1.4a là `UNLIMITED` công khai; finite capacity chưa được tuyên bố hoàn tất.

### Code

- `systems/inventory/inventory_transaction_result.gd`: status + requested/applied amount.
- `systems/inventory/inventory_transaction.gd`: pure get/can-add/add/can-remove/remove/transfer.
- `data/legacy_item_adapter.gd`: thêm guarded `set_count` cho commit/rollback.
- `scripts/player.gd`: stable add/read route qua transaction; thêm `remove_item_by_id`.
- `tools/validate_item_migration.gd`: regression transaction, Player và rejected drop.
- `docs/architecture/INVENTORY_TRANSACTIONS.md`: API, capacity, audit direct writer và U1.4b boundary.

### Validation

Lệnh `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1` đạt:

- Documentation: 25 required files, 23 Markdown files.
- Asset: 166/166, 0 verified, 166 quarantine/unknown, 69 runtime P0.
- Godot editor-load sạch.
- Content validator U1.3 pass.
- Inventory transaction/item migration pass.
- Main scene smoke 120 frame pass.
- Log ở `build/checks/*.log`.

### Compatibility và phần còn lại

- Save/data breaking change: none; backing dictionary/key legacy không đổi.
- Mapping stable runtime vẫn chỉ có `item.wood`.
- Capacity unlimited nên G03 inventory-full chưa đạt.
- Chest vẫn mutate trực tiếp; chuyển sang U1.4b.
- Crafting, food, furnace, cooking, compost, farm, ranch và altar còn direct legacy writer; danh sách/owner nằm trong `INVENTORY_TRANSACTIONS.md`.
- Không thêm/sửa asset; provenance status không đổi.
- Rollback: revert commit U1.4a, không cần data migration.

### Gói tiếp theo

U1.4b: migrate chest deposit/withdraw qua transaction, thêm finite slot/max-stack policy được inject từ catalog, mở mapping chỉ cho typed item trong chest scope và regression capacity/atomic batch. Nếu bootstrap catalog tăng dependency, owner/lifetime phải được ghi trước khi code.

## Lịch sử

- U1.3: typed Recipe/Building/Crop definitions và cross-reference validation.
- U1.2: stable wood pickup adapter.
- U1.1: stable content ID và registry.
- U0.1–U0.4: verified baseline/governance.
