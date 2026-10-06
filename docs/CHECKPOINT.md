# Checkpoint triển khai Paloria 3.0

## U1.10a — PetInstance identity

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Mỗi capture accepted tạo một unique `pet.*` instance ID bên cạnh stable `creature.*` species ID.
- Resolver vẫn deterministic bằng ID inject; roster chỉ có một backing dictionary và commit nguyên tử.
- Giữ capture reward, rarity/trait roll, summon/ranch/UI behavior; không mở save/job.

### Kết quả đã triển khai

- Thêm typed `PetInstance` snapshot/projection và validation identity.
- `CaptureOwnershipRequest` nhận `pet_instance_id`; resolver reject sai domain và project accepted instance vào party entry.
- Player tạo collision-checked ID bằng `ResourceUID`, trong khi pure regression dùng ID cố định.

### Validation hiện tại

- Baseline full gate xanh.
- Focused capture regression xanh, gồm invalid domain, stable projection, unique two-capture IDs và duplicate guard.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; chưa có save schema. Asset/provenance: none.
- Party vẫn `Array[Dictionary]`; typed instance là projection, không phải store song song.
- Active selection/summon vẫn theo slot index và thuộc U1.10b.
- Rollback: revert U1.10a; không cần migration runtime.

### Gói tiếp theo

U1.10b migrate active pet selection và summon lifecycle sang instance ID, giữ phím slot và presentation qua adapter. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
