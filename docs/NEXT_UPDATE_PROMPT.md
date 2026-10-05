# Prompt cho model tiếp theo — U1.9b Creature skill canary

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9b. Đọc `AGENTS.md`, checkpoint, data/creature/combat contracts và roadmap trước khi sửa.

## Mục tiêu

Audit species attack/charge writers và tạo typed skill definition/reference canary nhỏ nhất cho Flam, giữ damage/timing/telegraph hiện tại qua adapter. Không migrate ecology, drop resolution hoặc toàn bộ species catalog.

## Phạm vi bắt buộc

1. Baseline gate và field/caller/writer inventory cho attack dispatch, cooldown, telegraph và damage.
2. Stable skill ID; không dùng method name, animation, display text hoặc species index làm identity.
3. Typed skill definition/reference cho đúng một Flam attack canary, với validation/missing-reference regression.
4. Runtime compatibility giữ nguyên timing, damage, projectile/target guard và async lifecycle protection.
5. Không đổi asset, balance, collision, spawn, capture hoặc ecology/drop.
6. Full gate, docs/checkpoint, save/asset/rollback/manual gaps.

## Definition of Done

- Pure/resource và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, log scan và `git diff --check` sạch.
- Writer còn lại được phân loại rõ sang U1.9c.
