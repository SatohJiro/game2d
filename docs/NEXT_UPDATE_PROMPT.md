# Prompt cho model tiếp theo — U1.9c Creature ecology/drop boundary

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9c. Đọc `AGENTS.md`, checkpoint, creature/data/combat contracts và roadmap trước khi sửa.

## Mục tiêu

Audit toàn bộ ecology/drop writer và chọn đúng một ownership boundary nhỏ nhất có thể kiểm chứng. Ưu tiên tách deterministic drop decision/reference khỏi animation/despawn; không đồng thời migrate toàn bộ species hoặc mở rộng skill catalog.

## Phạm vi bắt buộc

1. Chạy baseline gate và lập caller/writer inventory cho drop selection, reward spawn, predator/prey và defeat commit.
2. Giữ stable item/species IDs; không dùng localized text, asset path, scene path hoặc species index làm identity mới.
3. Một pure command/result hoặc typed adapter canary có invalid/duplicate/missing-reference regression.
4. Giữ loot quantity, probability, defeat idempotency, capture exclusion và runtime presentation hiện tại.
5. Không đổi asset, balance, collision, spawn, save schema hoặc migrate skill writer còn lại.
6. Full gate, docs/checkpoint, save/asset/rollback/manual gaps.

## Definition of Done

- Pure/resource và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, log scan và `git diff --check` sạch.
- Ecology/drop writer chưa migrate được phân loại rõ, không tuyên bố hoàn tất U1.9 nếu gate chưa đủ.
