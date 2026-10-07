# Checkpoint triển khai Paloria 3.0

## U1.12w — world clock owner commit

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Main truyền `day_time` vào explicit save và chỉ commit clock sau load success.
- Save layer không tìm/mutate Main; failed load giữ nguyên runtime clock.
- Day duration/raid/boss/spawn rules giữ nguyên; autosave/UI/encounter persistence ngoài scope.

### Kết quả đã triển khai

- Thêm `Main.save_game/load_game/apply_world_clock/configure_save_path` composition boundary.
- Thêm `SaveCoordinatorResult.is_loaded()` để phân biệt load success với save success.
- Load clock refresh ambient trực tiếp, không chạy raid/boss/spawn transaction trong boundary.
- Sửa resource health parser để repository JSON round-trip chấp nhận số nguyên dạng JSON number, vẫn reject phân số.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Editor-load và focused coordinator regression xanh: Main clock 73.25 round-trip; corrupt primary+backup giữ clock 44.0.
- Regression repository Main scene chứng minh 10 tree/rock records sống qua JSON verification.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape/version không đổi; coordinator API cũ giữ nguyên, Main chỉ thêm caller boundary.
- Asset/provenance: none.
- Raid-cycle guard, boss/spawn timers, autosave/UI và chunk persistence chưa phủ.
- Rollback: revert Main clock boundary, `is_loaded`, JSON integer compatibility regression và docs U1.12w.

### Gói tiếp theo

U1.12x persist riêng raid-cycle guard theo `NEXT_UPDATE_PROMPT.md`.
