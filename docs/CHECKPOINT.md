# Checkpoint triển khai Paloria 3.0

## U1.12d — base/quest persistence contract

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Base level, active quest và claimed rewards phải dùng stable identity, không dùng localized title hoặc array index trong save.
- Load không reset progression và không chạy reward flow; quest đã claim không thể nhận thưởng lần hai.
- Giữ nguyên objective, EXP reward, unlock level và economy; không mở rộng building/crop/world delta.

### Kết quả đã triển khai

- Thêm `BaseQuestCatalog` với năm `quest.base.*` và typed `BaseProgressState`.
- BaseManager có claimed ledger, typed create/apply boundary và duplicate guard trước mọi reward side effect.
- Save v1 thêm DTO `base`; schema bắt prefix/order/level coherence, snapshot/apply resolve trước mutation.
- Thêm validator base progression vào full project gate và regression Save active/claimed round-trip + failure atomicity.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load, `validate_base_progression.gd` và `validate_save_schema.gd` xanh.
- Full `tools/check_project.ps1` xanh: 40 Markdown files, asset gates, editor load, toàn bộ gameplay/save validators gồm base progression và coordinator repository round-trip.
- Leak-aware scan `build/checks` không có script/parse/missing dependency/invalid node path hoặc orphan/leak warning.

### Compatibility, asset và giới hạn

- Save v1 shape thêm `base` nhưng version giữ 1 vì chưa có save phát hành; snapshot thiếu field mới fail closed. Sau release phải tăng version + migration.
- BaseManager giữ quest dictionaries/presentation hiện hữu; stable catalog/state chỉ sở hữu identity/persistence boundary.
- Asset/provenance: none. Autosave/UI và building/crop/world persistence ngoài phạm vi.
- Rollback: revert progression catalog/state, BaseManager ledger, save DTO/adapters, gate/validator và docs U1.12d.

### Gói tiếp theo

Sau full gate xanh, U1.12e thiết kế building instance identity và placement delta tối thiểu. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
