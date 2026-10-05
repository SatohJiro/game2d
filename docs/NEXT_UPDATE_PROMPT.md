# Prompt cho model tiếp theo — U1.9l Mushroom typed definition

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9l. Đọc `AGENTS.md`, checkpoint, `DATA_CONTRACTS.md` và creature definition contract trước khi sửa.

## Mục tiêu

Mở rộng typed creature catalog cho riêng Mushroom, dùng stable `creature.mushroom` làm authority cho stats/behavior mà giữ runtime compatibility.

## Phạm vi bắt buộc

1. Baseline gate; audit Mushroom legacy snapshot, stable ID, stats và behavior fields.
2. Thêm/validate Mushroom `CreatureDefinition` cùng behavior profile theo pattern Flam/Slime.
3. Runtime adapter ưu tiên typed Mushroom definition nhưng giữ species index, texture, localized display và behavior hiện hữu.
4. Regression cho catalog reference, stat parity, prey role và Beast legacy fallback.
5. Không migrate Mushroom spore skill/drop execution, Beast/Dragon, asset hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining catalog audit.

## Definition of Done

- Content validator và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi remaining species/skill/drop catalog chưa đạt gate.
