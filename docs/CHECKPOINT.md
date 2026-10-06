# Checkpoint triển khai Paloria 3.0

## U1.11c — validated runtime load apply

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Validate Save v1 và resolve toàn bộ item/species/stance trước khi mutate Player.
- Invalid hoặc unsupported snapshot giữ nguyên position, inventory, roster và active pet.
- Chưa đọc/ghi file, autosave, checksum, backup, migration hoặc UI slot.

### Kết quả đã triển khai

- Thêm `SaveApplyPlan/Result/Adapter`: stable inventory map ngược về single legacy store, player scalars/needs được apply và world clock trả về caller.
- Pet roster dựng lại qua typed species authority; active pet summon qua Player boundary và stance qua pet command API.
- `LegacySpeciesAdapter` sở hữu compatibility presentation cần để dựng runtime pet từ stable species ID.

### Validation hiện tại

- Baseline full gate xanh.
- Focused Save regression xanh: valid apply, inventory mapping, roster/stance/world clock và unsupported-reference no-mutation.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset inventory/action, editor import/load và toàn bộ focused gameplay/save validators đều đạt.

### Compatibility, asset và giới hạn

- Schema vẫn v1; chưa có file phát hành cần migration. Không thêm asset; presentation dùng lại baseline quarantine.
- Rarity/trait và stance pet không active chưa persist trong v1; apply dùng compatibility defaults đã ghi ở save contract.
- Rollback: revert U1.11c; U1.11a–b schema/snapshot vẫn độc lập.

### Gói tiếp theo

U1.11d tạo repository JSON với temp-write/atomic replace và backup recovery; chưa autosave hoặc UI slot. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
