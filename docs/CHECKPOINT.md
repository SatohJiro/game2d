# Checkpoint triển khai Paloria 3.0

## U1.11e — fail-closed migration harness

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Migration làm việc trên deep copy và chỉ trả snapshot đã tới current version + qua schema validation.
- Future version, missing/ambiguous step, cycle hoặc invalid output đều fail closed.
- Không tạo migration sản xuất giả khi chưa có save format pre-v1 phát hành.

### Kết quả đã triển khai

- Thêm `SaveMigrationStep/Registry/Result` với typed statuses và applied-version trace.
- Registry route tuần tự theo declared version, phát hiện cycle và bắt output version khớp step.
- Current v1 là validated no-op; repository chưa tự migrate hoặc apply gameplay.
- Thêm focused migration validator vào full project gate.

### Validation hiện tại

- Baseline full gate xanh.
- Focused regression xanh: v1 no-op/deep-copy, injected route và future/missing/cycle/invalid/ambiguous failures.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset gates, editor import/load, gameplay validators và toàn bộ Save validators đều đạt.

### Compatibility, asset và giới hạn

- Save schema vẫn v1; production registry rỗng vì không có pre-v1 release. Không thêm/thay asset.
- Transform dùng Callable nội bộ registry, không serialize vào save DTO.
- Rollback: revert U1.11e; repository và runtime adapters U1.11a–d vẫn hoạt động độc lập.

### Gói tiếp theo

U1.11f tạo SaveCoordinator explicit save/load cho Player + world clock bằng snapshot/repository/migration/apply hiện có; chưa autosave hoặc UI slot. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
