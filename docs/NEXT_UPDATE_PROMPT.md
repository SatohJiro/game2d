# Prompt cho model tiếp theo — U1.9o Dragon fireball definition

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9o. Đọc `AGENTS.md`, checkpoint, `CREATURE_SKILL_CONTRACT.md` và creature definition contract trước khi sửa.

## Mục tiêu

Migrate riêng Dragon fireball tuning sang typed `SkillDefinition` và stable skill ID, giữ gameplay/lifecycle quan sát được.

## Phạm vi bắt buộc

1. Baseline gate; audit Dragon melee/fireball selection và toàn bộ fireball constants/runtime guards.
2. Thêm Dragon fireball `SkillDefinition`, reference từ `creature.dragon`, registry validation và adapter resolution theo species.
3. Giữ melee branch legacy; không dùng Flam skill ID hoặc ngầm chia sẻ balance authority.
4. Regression cho cooldown, recovery, damage multiplier, travel, hit radius, dispatch và stale lifecycle guards.
5. Không migrate Dragon melee, Slime hop, Mushroom spore, Beast charge, drop execution, asset hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining writer audit.

## Definition of Done

- Content validator và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi remaining skill/drop execution chưa đạt gate.
