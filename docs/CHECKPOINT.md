# Checkpoint triển khai Paloria 3.0

## U1.12u — tree depletion persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Sáu tree tĩnh giữ health và respawn time qua Save v1 bằng stable resource identity.
- Restore không gọi hit/break/drop/VFX và không serialize enum, Node hoặc scene path.
- State sống/depleted không coherent fail trước mutation; rock/chunk streaming ngoài scope.

### Kết quả đã triển khai

- Thêm `ResourceDepletionState/Record`, `world.resource_deltas` và sáu ID `resource.tree_*`.
- Tree sống giữ health 1–60/timer 0; depleted giữ health 0/timer trong `(0,18]`.
- Refactor riêng tree coroutine thành deterministic respawn countdown; rock giữ lifecycle cũ.
- Save cũ thiếu `resource_deltas` vẫn hợp lệ và dùng state scene mặc định.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Baseline full gate xanh trước thay đổi.
- Focused regression giữ partial health 37 và depleted timer 9.5; invalid health 61 fail trước mutation; restore không tạo drop.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape pre-release vẫn version 1; `resource_deltas` mới optional khi đọc save cũ.
- Asset/provenance: none.
- Rock depletion, static spawn identity và chunk persistence chưa phủ.
- Rollback: revert tree stable IDs/state/adapter, Save world field, regression và docs U1.12u.

### Gói tiếp theo

U1.12v persist riêng rock depletion theo `NEXT_UPDATE_PROMPT.md`.
