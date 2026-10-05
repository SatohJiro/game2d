# Prompt cho model tiếp theo — U1.9p Mushroom spore definition

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9p. Đọc `AGENTS.md`, checkpoint và `CREATURE_SKILL_CONTRACT.md` trước khi sửa.

## Mục tiêu

Migrate riêng Mushroom spore projectile tuning sang typed `SkillDefinition` và stable skill ID, giữ gameplay/lifecycle quan sát được.

## Phạm vi bắt buộc

1. Baseline gate; audit Mushroom kiting/escape/dispatch và toàn bộ spore constants/runtime guards.
2. Thêm Mushroom spore `SkillDefinition`, reference từ `creature.mushroom`, registry validation và adapter resolution.
3. Refactor projectile adapter đủ nhỏ để dùng typed tuning nhưng giữ texture/modulate/scale/text và RNG ordering.
4. Regression cho cooldown, recovery, damage, travel, hit radius, dispatch và stale lifecycle guards.
5. Không migrate Slime hop, Beast charge, Dragon melee, drop execution, asset hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining writer audit.

## Definition of Done

- Content validator và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi remaining skill/drop execution chưa đạt gate.
