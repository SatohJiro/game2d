# Prompt cho model tiếp theo — U1.9n Dragon typed definition

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9n. Đọc `AGENTS.md`, checkpoint, `DATA_CONTRACTS.md` và creature definition contract trước khi sửa.

## Mục tiêu

Hoàn tất typed creature catalog cho riêng Dragon, dùng stable `creature.dragon` làm authority cho stats/behavior mà giữ runtime compatibility.

## Phạm vi bắt buộc

1. Baseline gate; audit Dragon legacy snapshot, stable ID, stats và predator role.
2. Thêm/validate Dragon `CreatureDefinition` cùng stable item reference cần thiết theo pattern hiện hữu.
3. Runtime adapter ưu tiên typed Dragon definition nhưng giữ species index, texture, localized display và predator behavior.
4. Regression cho catalog reference, stat parity, forced-elite scaling, predator role và invalid-index fallback.
5. Không migrate Dragon melee/fireball/drop execution, asset hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining skill/drop catalog audit.

## Definition of Done

- Content validator và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi remaining skill/drop execution chưa đạt gate.
