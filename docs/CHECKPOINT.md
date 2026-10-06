# Checkpoint triển khai Paloria 3.0

## U1.10b — summon lifecycle

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Active pet được nhận diện bằng persistent instance ID, không bằng Node hoặc display text.
- Một roster instance có tối đa một summoned node; trong tree có tối đa một active companion.
- Giữ input slot 1–3, stats, HUD/audio và pet AI; không mở command wheel/job/save.

### Kết quả đã triển khai

- Thêm pure `PetSummonRequest/Result/Policy` với SUMMON/REPLACE/NO_CHANGE/INVALID.
- Player giữ `active_pet_instance_id`; CompanionPet nhận `pet_instance_id` từ roster entry.
- Same-instance không respawn; replace tháo node cũ khỏi tree trước khi add node mới.
- Thêm `validate_pet_summon.gd` vào full project gate.

### Validation hiện tại

- Baseline full gate xanh.
- Focused policy + Player scene regression xanh; first summon, same-slot và replace đều khóa single-node invariant.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; chưa có save schema. Asset/provenance: none.
- Slot index chỉ còn là input adapter; roster dictionary vẫn là backing store duy nhất.
- Command stance hiện vẫn toggle trực tiếp và thuộc U1.10c.
- Rollback: revert U1.10b; PetInstance roster U1.10a không cần migration.

### Gói tiếp theo

U1.10c tạo stable pet command intent/policy cho stance hiện tại, giữ phím command và AI behavior qua adapter. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
