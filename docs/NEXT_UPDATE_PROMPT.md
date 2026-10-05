# Prompt cho model tiếp theo — U1.9j Drinking-entry decision

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9j. Đọc `AGENTS.md`, checkpoint và creature ecology/transition contracts trước khi sửa.

## Mục tiêu

Tách drinking-entry decision trong `start_wander()` bằng pure policy, injected roll/distance và transition owner mà không thay đổi natural-action precedence.

## Phạm vi bắt buộc

1. Baseline gate; audit water-source guard, `<320px` distance, chance `<0.25`, duration 3–5 giây và RNG ordering.
2. Pure request/result cho drinking decision và stable transition event.
3. Giữ sleep → drink → grazing → wander precedence, pond direction và presentation sau accepted apply.
4. Actor regression cho accepted/rejected boundaries, missing water, protected state và stale result.
5. Không đổi asset, skill, drop, spawn, species catalog hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining-writer audit.

## Definition of Done

- Pure/transition regression và actor compatibility xanh.
- Full `tools/check_project.ps1`, leak-aware log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi remaining species catalog chưa đạt gate.
