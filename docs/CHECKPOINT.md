# Checkpoint triển khai Paloria 3.0

## U1.10d — explicit pet commands

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Mở explicit work/combat/follow commands trên deterministic command boundary hiện hữu.
- Cùng stance trả no-change, không mutate AI hoặc presentation; invalid input fail closed.
- Giữ cycle command, phím hiện tại, HUD và AI branches; không mở target/job/save/UI.

### Kết quả đã triển khai

- Thêm `pet.command.auto_work`, `combat_assist`, `follow_protect`.
- `PetCommandResult.NO_CHANGE` phân biệt idempotent success với mutation thực.
- CompanionPet chỉ apply/present `APPLIED`; cycle adapter giữ compatibility.

### Validation hiện tại

- Baseline full gate xanh.
- Focused regression xanh cho direct mapping, no-change, invalid domain/command và actor apply.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; chưa có save schema. Asset/provenance: none.
- Target selection, job reservation và command wheel hoãn sang U5/U3.
- Rollback: revert U1.10d; cycle command U1.10c vẫn hoạt động.

### Gói tiếp theo

U1.11a tạo Save v1 schema/DTO envelope và validation thuần, chưa ghi file hoặc migrate runtime state. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
