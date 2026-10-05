# Prompt cho model tiếp theo — U1.9g Hunt lifecycle closure

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9g. Đọc `AGENTS.md`, checkpoint và creature ecology/transition/combat contracts trước khi sửa.

## Mục tiêu

Đưa HUNTING_PREY target-loss/timeout và contact exit qua transition owner, giữ movement/contact/damage hiện hữu. Không migrate skill catalog hoặc toàn bộ species.

## Phạm vi bắt buộc

1. Baseline gate; audit direct state/prey-target writers trong `panic_from_predator()` và `handle_prey_hunt()`.
2. Stable transition events cho hunt abort/contact; stale/protected result guard.
3. Actor regression cho invalid prey, timeout, contact và repeated/stale callback.
4. Giữ hunt speed ×1.05, contact `<42px`, prey damage ×0.7, abort timer 2s, contact recovery 3s và feedback.
5. Không đổi sleep/drink, asset, skill, drop, spawn hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining-writer audit.

## Definition of Done

- Transition/pure regression và actor compatibility xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi catalog/sleep-drink writer còn lại chưa đạt gate.
