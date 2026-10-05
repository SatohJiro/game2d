# Prompt cho model tiếp theo — U1.9h Predator-threat panic callback

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9h. Đọc `AGENTS.md`, checkpoint và creature ecology/transition contracts trước khi sửa.

## Mục tiêu

Đưa `panic_from_predator()` qua transition owner mà không thay đổi predator/prey selection hoặc hunt lifecycle đã khóa.

## Phạm vi bắt buộc

1. Baseline gate và audit direct writer trong `panic_from_predator()`.
2. Stable transition event cho predator-threat panic; stale/protected result guard.
3. Giữ threat target, FLEE 4 giây, floating text, shake audio và CAPTURING/FLEE guards.
4. Actor regression cho accepted panic, capture/FLEE guard, invalid predator và repeated/stale result.
5. Không đổi sleep/drink, asset, skill, drop, spawn, species catalog hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining-writer audit.

## Definition of Done

- Transition/pure regression và actor compatibility xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi sleep/drink và remaining species catalog chưa đạt gate.
