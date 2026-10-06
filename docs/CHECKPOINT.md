# Checkpoint triển khai Paloria 3.0

## U1.11a — Save v1 schema foundation

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Định nghĩa versioned, JSON-safe Save v1 envelope bằng stable IDs.
- Validate shape/range/reference thuần; không serialize Node/Callable/Resource/runtime value.
- Chưa đọc/ghi file, apply runtime, autosave, migration hay UI slot.

### Kết quả đã triển khai

- Thêm `SaveV1Schema` và `SaveValidationResult` cho player/inventory/pets/world DTO.
- Khóa unique pet ID, active roster reference, item/species domains và scalar ranges.
- Hỗ trợ JSON integral-float semantics nhưng reject fraction/negative/non-finite theo field.
- Thêm focused save validator vào full project gate.

### Validation hiện tại

- Baseline full gate xanh.
- Focused regression xanh cho valid + JSON round-trip, invalid version/ID/range/reference và Node/Callable/Vector2 rejection.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: schema v1 mới, chưa có save file phát hành nên migration cũ là none.
- Runtime adapter/file persistence: chưa có. Asset/provenance: none.
- `world.entity_deltas` mới khóa container shape, payload thuộc U2/U1.11 package sau.
- Rollback: revert U1.11a; gameplay runtime không đổi.

### Gói tiếp theo

U1.11b tạo Player/pet/inventory runtime → Save v1 snapshot adapter với stable item mapping và không mutate source. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
