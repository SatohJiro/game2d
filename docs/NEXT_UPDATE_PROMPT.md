# Prompt cho model tiếp theo — U1.9e Predator/prey selection

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9e. Đọc `AGENTS.md`, checkpoint và creature perception/transition/ecology contracts trước khi sửa.

## Mục tiêu

Tách deterministic predator/prey candidate selection khỏi `check_predator_prey_ecosystem()`; group scan chỉ thu candidate và actor apply accepted result. Giữ cadence, distance, role và capture guards hiện hữu.

## Phạm vi bắt buộc

1. Baseline gate; audit group ordering, duplicate/invalid candidate, stable candidate identity và direct hunt/panic writers.
2. Pure candidate request/result với deterministic tie-break; không giữ Node/ObjectID trong persistent data.
3. Actor compatibility regression cho no candidate, nearest/tie candidate và capture guard.
4. Giữ pack scan cadence 2.0–3.5s, hunt distance `<210px`, duration 6s và presentation hiện hữu.
5. Không đổi grazing, hunting contact/damage, asset, skill, drop, spawn hoặc save schema.
6. Full gate, docs/checkpoint, rollback và remaining-writer audit.

## Definition of Done

- Pure selection và actor adapter regression xanh.
- Full `tools/check_project.ps1`, log scan và `git diff --check` sạch.
- Direct writer còn lại được phân loại; không tuyên bố hoàn tất U1.9 khi natural actions/catalog chưa đạt gate.
