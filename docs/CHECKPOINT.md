# Checkpoint triển khai Paloria 3.0

## U1.12c — pet metadata persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Rarity, trait và stance của mỗi roster pet dùng stable identity; localized badge/name không đi vào save làm identity.
- Snapshot/apply giữ metadata và stance của cả pet active lẫn inactive.
- Không đổi rarity roll, stat multiplier, pet combat/job behavior hoặc HUD text.

### Kết quả đã triển khai

- Thêm `PetMetadataCatalog` với bốn `pet.rarity.*`, bảy `pet.trait.*` và projection presentation cũ.
- Capture/PetInstance phát và validate stable metadata; pet mới có `pet.stance.auto_work` trong roster.
- Player ghi stance active về roster trước node replacement và restore stance khi summon.
- Save v1 bắt buộc rarity/trait/stance allowlist; snapshot/apply round-trip active + inactive pet và dựng lại presentation text từ catalog.

### Validation hiện tại

- Godot editor import/load headless xanh.
- `validate_capture.gd`, `validate_pet_summon.gd`, `validate_save_schema.gd` xanh.
- Full `tools/check_project.ps1` xanh: documentation, asset integrity/action, editor load và toàn bộ gameplay/save validators.
- Leak-aware scan `build/checks` không có script/parse/missing dependency/invalid node path hoặc orphan/leak warning.

### Compatibility, asset và giới hạn

- Save v1 shape đổi tại `pets[]` nhưng version giữ 1 vì chưa có save phát hành; snapshot thiếu metadata mới fail closed. Sau release phải tăng version + migration.
- Runtime roster vẫn là single source; field badge/trait legacy được giữ cho HUD/ranch compatibility.
- Asset/provenance: none.
- Base/quest, building/crop/world delta và autosave/UI ngoài phạm vi.
- Rollback: revert catalog, stable roster fields, Player stance bridge, save schema/adapters và regression/docs U1.12c.

### Gói tiếp theo

Sau full gate xanh, U1.12d thiết kế typed stable persistence cho base/quest progress để chặn reset và reward lặp. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
