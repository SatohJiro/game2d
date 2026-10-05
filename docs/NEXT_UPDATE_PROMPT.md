# Prompt cho model tiếp theo — U1.9d Creature ecology canary

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9d. Đọc `AGENTS.md`, checkpoint và creature/data/combat/drop contracts trước khi sửa.

## Mục tiêu

Audit predator/prey, grazing, hunting và panic-FLEE writers; chọn một ecology decision/ownership boundary nhỏ cho Flam hoặc một pure profile policy có actor adapter. Không mở rộng typed species/skill/drop catalog trong cùng package.

## Phạm vi bắt buộc

1. Baseline gate và caller/writer inventory cho ecology role, prey selection, grazing/hunting entry và damage panic.
2. Stable species/role/event identity; không dùng display text, animation, scene path hoặc species index làm identity mới.
3. Pure request/result hoặc policy với deterministic regression và actor compatibility canary.
4. Giữ cadence, probability, distance, state guard, combat/capture và presentation hiện hữu.
5. Không đổi asset, balance, drop, skill, spawn hoặc save schema.
6. Full gate, docs/checkpoint, save/asset/rollback/manual gaps.

## Definition of Done

- Pure policy và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, log scan và `git diff --check` sạch.
- Writer chưa migrate được phân loại rõ; không tuyên bố hoàn tất U1.9 nếu ecology/catalog gate chưa đủ.
