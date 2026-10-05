# Checkpoint triển khai Paloria 3.0

## U1.9a — CreatureDefinition Flam canary

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- `creature.flam` dùng stable ID và typed authority cho stats/behavior/drop reference.
- Không tạo store song song; runtime legacy-shaped snapshot chỉ là compatibility projection.
- Giữ nguyên balance, spawn, combat/capture behavior, asset và scene hierarchy.

### Kết quả đã triển khai

- Thêm `CreatureDefinition`, embedded `CreatureBehaviorProfile` và canary `flam.tres`.
- Flam giữ 80 HP, speed 105, power 14, neutral ecology role và drop `item.pal_ore`.
- `LegacySpeciesAdapter.create_runtime_snapshot()` chiếu typed fields về shape cũ.
- Xóa sáu field migrated khỏi row Flam; chỉ còn name/element/texture presentation.
- Registry cross-reference kiểm tra stable drop item; catalog tăng 10→11 definition.

### Validation hiện tại

- Focused content validator đạt valid/invalid definition, duplicate/missing reference và project catalog.
- Creature actor regression đạt stable ID, stats, drop mapping và no-parallel-source assertion.
- Full `tools/check_project.ps1` đạt: documentation/asset gates, editor load, toàn bộ domain regression và main smoke xanh.
- `git diff --check` và log scan sạch.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; party snapshot format giữ nguyên và đã có stable species ID từ U1.7c.
- Asset/provenance: không thêm/sửa asset; texture Flam hiện hữu vẫn quarantine/unknown.
- Bốn species còn lại vẫn dictionary-authoritative.
- Skill execution, ecology/drop resolver và random natural-state entry chưa migrate.
- Rollback: revert package U1.9a; không cần migration.

### Gói tiếp theo

U1.9b audit species attack/charge và tạo typed skill reference/definition canary nhỏ nhất. Không migrate ecology/drop trong cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.

## Hướng sản phẩm phải giữ

- Definition dùng stable ID và không lưu Node/ObjectID, sẵn sàng cho save/chunk U2.
- Paloria Luminous Town vẫn là initiative U2–U4; content phải nguyên bản và có provenance.
- Asset admission mới còn bị chặn vì `game-dev` CLI chưa có trong PATH.
