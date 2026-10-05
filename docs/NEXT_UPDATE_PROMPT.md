# Prompt cho model tiếp theo — U1.9m Beast typed definition

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9m. Đọc `AGENTS.md`, checkpoint, `DATA_CONTRACTS.md` và creature definition contract trước khi sửa.

## Mục tiêu

Mở rộng typed creature catalog cho riêng Beast, dùng stable `creature.beast` làm authority cho stats/behavior mà giữ runtime compatibility.

## Phạm vi bắt buộc

1. Baseline gate; audit Beast legacy snapshot, stable ID, stats và predator role.
2. Thêm/validate Beast `CreatureDefinition` theo pattern hiện hữu.
3. Runtime adapter ưu tiên typed Beast definition nhưng giữ species index, texture, localized display và predator behavior.
4. Regression cho catalog reference, stat parity, predator role và Dragon legacy fallback.
5. Không migrate Beast charge/drop execution, Dragon, asset hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining catalog audit.

## Definition of Done

- Content validator và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi Dragon/remaining skill/drop catalog chưa đạt gate.
