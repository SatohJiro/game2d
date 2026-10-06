# Checkpoint triển khai Paloria 3.0

## U1.10c — pet command boundary

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Route command stance hiện hữu qua stable intent và deterministic result.
- Player dispatch intent; CompanionPet sở hữu mutation/presentation; invalid command không mutate.
- Giữ phím command, chu kỳ AI, floating text và HUD behavior; không mở job/save/command wheel.

### Kết quả đã triển khai

- Thêm `PetCommandRequest/Result/Policy` với stable command/stance IDs.
- Chu kỳ auto-work → combat-assist → follow-protect → auto-work được tách khỏi Node.
- `apply_pet_command()` commit accepted result; `toggle_stance()` còn là compatibility adapter.
- Player không còn đọc enum `AGGRESSIVE` không tồn tại; HUD dùng result stance ID.

### Validation hiện tại

- Baseline full gate xanh.
- Focused pure + actor regression xanh cho đủ ba transition, unsupported/invalid guard và summon lifecycle cũ.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; chưa có save schema. Asset/provenance: none.
- Enum stance và AI branches hiện hữu giữ nguyên sau actor adapter.
- Explicit follow/guard/attack/work/return intents còn thuộc U1.10d.
- Rollback: revert U1.10c; PetInstance/summon U1.10a–b không cần migration.

### Gói tiếp theo

U1.10d mở stable explicit stance commands trên cùng policy, giữ cycle command làm input compatibility. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
