# Prompt cho model tiếp theo — U1.9f Natural-action grazing decision

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9f. Đọc `AGENTS.md`, checkpoint và creature transition/ecology contracts trước khi sửa.

## Mục tiêu

Tách grazing-entry decision khỏi `start_wander()` bằng injected roll và typed role snapshot, nhưng giữ nguyên sleep → drink → grazing → wander precedence và số/thứ tự RNG call quan sát được.

## Phạm vi bắt buộc

1. Baseline gate; audit từng RNG call/short-circuit trong `start_wander()`.
2. Pure grazing request/result với stable event; exact probability boundary regression.
3. Actor compatibility cho neutral Flam, prey species, protected state và accepted transition.
4. Giữ probability 0.22, duration range 2.5–4.0, presentation và fallback wander.
5. Không migrate sleep/drink decision, hunt contact, asset, skill, drop, spawn hoặc save.
6. Full gate, docs/checkpoint, rollback và remaining-writer audit.

## Definition of Done

- Pure decision và actor regression xanh; RNG call ordering có assertion hoặc inventory rõ.
- Full `tools/check_project.ps1`, log scan và `git diff --check` sạch.
- Không tuyên bố hoàn tất U1.9 khi hunt/natural/catalog writer còn lại chưa đạt gate.
