# Prompt cho model tiếp theo — U1.9i Sleep-entry decision

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9i. Đọc `AGENTS.md`, checkpoint và creature ecology/transition contracts trước khi sửa.

## Mục tiêu

Tách sleep-entry decision trong `start_wander()` bằng pure policy/injected RNG và transition owner, không thay đổi natural-action precedence.

## Phạm vi bắt buộc

1. Baseline gate; audit sleep chance, duration, eligibility và RNG call ordering.
2. Pure request/result cho sleep decision và stable transition event.
3. Giữ exact chance boundary, duration range, sleep → drink → grazing → wander precedence và short-circuit RNG.
4. Actor regression cho accepted/rejected boundary, protected state và repeated/stale result.
5. Không migrate drinking, asset, skill, drop, spawn, species catalog hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining-writer audit.

## Definition of Done

- Pure/transition regression và actor compatibility xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi drinking và remaining species catalog chưa đạt gate.
