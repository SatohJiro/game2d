# Checkpoint triển khai Paloria 3.0

## U1.8a — Creature player-perception cadence

Trạng thái: `VERIFIED` ngày 2026-10-04; package branch `work/u1.8a-creature-perception`.

### Mục tiêu và invariant

- Bỏ player group scan khỏi mỗi physics frame của WildCreature.
- Chuyển selection/alert/suspicion rule sang pure deterministic policy.
- Protected states và defeated không query hoặc bị perception ghi đè.
- Giữ nguyên combat, capture, pack/ecosystem, scene và balance.

### Kết quả đã triển khai

- Thêm candidate/request/result/policy thuần trong `systems/creature/`.
- Thêm `CreaturePerceptionCadence` interval 0,20 giây và metric `perception_query_count`.
- Node adapter map transient instance ID về Node chỉ trong query hiện tại.
- Deterministic selection: distance trước, candidate ID sau.
- Giữ ngưỡng normal/elite/raid 115/150/280, suspicion +65 và sleep wake cũ.
- Protected states bỏ qua group scan; target loss vẫn do state timer legacy xử lý.

Contract và audit đầy đủ: `architecture/CREATURE_PERCEPTION_CONTRACT.md`.

### Validation hiện tại

- Focused `validate_creature_perception.gd` đạt.
- Full `tools/check_project.ps1` đạt sau cập nhật tài liệu: 26 required file, 31 Markdown file, 166 asset inventory/action; mọi Godot regression và main smoke xanh.
- Metric regression: 20 tick × 0,05 giây tạo đúng 5 query thay cho baseline 60 query/giây ở 60 physics FPS, giảm 91,67% số lần player group scan có thể xảy ra.

### Compatibility, save, asset và giới hạn

- Save/data breaking change: none; cadence, count và instance ID đều transient.
- Asset/provenance: không thêm hoặc sửa asset; 166 asset giữ nguyên trạng thái.
- Pack/ecosystem còn hai wild-creature group scan mỗi chu kỳ 2,0–3,5 giây; howl scan theo event.
- Nhiều writer state/target/velocity và async attack vẫn trong `creature.gd`; U1.8 chưa hoàn tất.
- Manual editor test còn cần cho response latency, sleep wake, raid và nhiều candidate.
- Rollback: revert commit U1.8a; không cần migration.

### Gói tiếp theo

U1.8b tách transition request/result và một transition owner cho phần state loop đã chọn. Không triển khai skill/drop U1.9 hoặc refactor toàn bộ Creature trong một lượt. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.

## Hướng sản phẩm phải giữ

- Paloria Luminous Town vẫn là initiative world/art/audio ưu tiên sau U2 chunk/persistence contract.
- Không sao chép map, sprite hoặc nhạc của Your Name; content phát hành phải nguyên bản và có provenance/license.
- `game-dev` CLI vẫn chưa có trong PATH nên asset admission mới còn bị chặn.
