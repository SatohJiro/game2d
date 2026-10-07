# Checkpoint triển khai Paloria 3.0

## U1.12ab — world-boss actor ownership và defeat signal

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Main sở hữu đúng một world-boss actor bằng reference và stable identity.
- Duplicate spawn, callback lặp, actor thường và altar boss phải fail closed.
- Creature signal up trước khi free; reward/drop hiện hữu không đổi và Save v1 chưa mở rộng.

### Kết quả đã triển khai

- Main giữ `world_boss_actor`, group `persistent_world_bosses` và metadata `boss.world_dragon_1`.
- `spawn_boss()` trả result, chỉ nhận PENDING và từ chối actor/lifecycle đã active hoặc defeated.
- Creature phát `defeated(actor, encounter_instance_id)`; Main chỉ commit DEFEATED khi reference/group/meta/ID cùng khớp.
- `spawn_boss(false)` suppress banner/audio cho test/future restore, không đổi combat/reward/drop.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused editor-load/regression xanh: đúng một actor; duplicate spawn, normal/altar actor và duplicate callback fail closed; owned signal commit defeated.
- Full `tools/check_project.ps1` xanh: 42 Markdown files, asset/content gates, editor load, toàn bộ gameplay/save validators và world-boss ownership regression; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; ownership state chưa được nối Save v1.
- Asset/provenance: none.
- Active/defeated actor restore, atomic failed load và chunk persistence chưa phủ.
- Rollback: revert Creature signal, Main ownership/guard, regression và docs U1.12ab.

### Gói tiếp theo

U1.12ac admit world-boss state vào Save v1 theo `NEXT_UPDATE_PROMPT.md`.
