# Checkpoint triển khai Paloria 3.0

## U1.11b — runtime snapshot adapter

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Project Player/inventory/pet runtime sang Save v1 DTO, deep-copy và validate trước accepted.
- Không mutate source; unknown legacy item fail closed, không silently drop/partial snapshot.
- Chưa apply load, ghi file, autosave, migration hoặc UI slot.

### Kết quả đã triển khai

- Thêm `SaveSnapshotAdapter/Result` cho position/progression/needs/inventory/roster/active stance/world clock.
- Admit `item.stone` và `item.iron_ingot` definitions + mappings để phủ inventory mặc định.
- Active pet lấy stance actor; pet không active mặc định auto-work do roster chưa giữ mutable stance.

### Validation hiện tại

- Baseline full gate xanh.
- Focused content và snapshot regression xanh: scene Player thật, stable mapping, active stance, deep-copy và unmapped-key atomic failure.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset inventory/action, editor import/load và toàn bộ focused gameplay/save validators đều đạt; log không còn lỗi Godot bị gate phát hiện.

### Compatibility, asset và giới hạn

- Save schema vẫn v1; chưa có file phát hành/migration cũ. Runtime gameplay không mutate.
- Stone/iron dùng asset baseline hiện hữu, provenance vẫn `QUARANTINE/UNKNOWN`; không thêm asset.
- Food/fertilizer/crop legacy keys chưa admit sẽ block snapshot rõ ràng nếu hiện diện.
- Rollback: revert U1.11b; schema U1.11a vẫn độc lập.

### Gói tiếp theo

U1.11c tạo atomic runtime apply transaction cho Player/inventory/pet roster từ validated DTO, chưa ghi file. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
