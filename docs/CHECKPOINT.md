# Checkpoint triển khai Paloria 3.0

## U1.4b — chest atomic transfer và finite capacity

Trạng thái: VERIFIED ngày 2026-10-04; package sẽ được fast-forward từ branch work/u1.4b-chest-capacity vào main.

### Kết quả

- Thêm CapacityPolicy.STACK_SLOTS: used slots là tổng ceil(count/max_stack) của item mapped.
- Max slots và max-stack lookup được owner inject; domain service không load Resource.
- Missing max-stack trả MISSING_DEFINITION; full slots trả CAPACITY_EXCEEDED.
- transfer_batch_to chạy toàn batch trên shadow stores rồi mới commit; failure không chuyển một phần.
- Mapping mở cho item.wood, item.pal_ore, item.berry.
- Chest mặc định 12 slot, inject max-stack từ ba ItemDefinition.
- Chest deposit/withdraw mapped item atomic; stone/ingot legacy không bị quick batch đụng tới.
- Pet deposit mapped item đi qua finite transaction.

### Regression và gate

tools/check_project.ps1 đạt:

- 25 required docs, 23 Markdown.
- 166/166 asset; provenance vẫn 0 verified/166 quarantine.
- Godot editor-load sạch.
- Content validation pass.
- Capacity/batch/chest/item migration validation pass.
- Main smoke 120 frame pass.

Regression gồm exact stack, mở stack, hết slot, missing definition, batch rollback, conservation, chest deposit/withdraw và bảo toàn item unmigrated.

### Compatibility và giới hạn

- Save/data breaking change: none; dictionary/key legacy vẫn là backing store.
- Player capacity vẫn unlimited; chest finite capacity áp dụng cho ba item typed/mapped.
- Stone, iron ingot và pal ingot trong chest chưa có typed definition/mapping.
- Crafting, food, furnace, cooking, compost, farm, ranch và altar còn direct legacy writer.
- Không thêm/sửa asset. Rollback bằng revert commit U1.4b.
- U1.4 hoàn tất theo scope transaction foundation; mở rộng mọi consumer thuộc package domain tương ứng.

### Gói tiếp theo

U1.5 tạo pure combat request/result với faction/status/knockback data và migrate đúng Player + một wild creature damage boundary. Animation/VFX chỉ đọc result; không đổi toàn bộ AI/skills trong cùng package.

## Lịch sử

- U1.4a: pure inventory transaction + Player/drop.
- U1.3: typed domain definitions.
- U1.2: stable wood adapter.
- U1.1: stable IDs/registry.
