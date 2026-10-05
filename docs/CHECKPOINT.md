# Checkpoint triển khai Paloria 3.0

## U1.9e — Deterministic predator/prey selection

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- Tách prey selection khỏi SceneTree group ordering; scan chỉ thu candidate, policy thuần chọn result.
- Giữ scan cadence 2.0–3.5s, strict hunt distance `<210px`, hunt duration 6s, role/capture guards và presentation.
- Không đổi RNG ordering, grazing, hunt contact/damage, asset, skill, drop, spawn hoặc save.

### Kết quả đã triển khai

- Thêm typed candidate/request/result/policy không chứa Node/ObjectID.
- Chọn nearest candidate; equal-distance tie-break lexical scan-local key.
- Duplicate key giữ nearest observation; invalid/non-prey/capture-active/out-of-range bị lọc deterministic.
- Neutral Flam và blocked predator bỏ group scan; `ecology_query_count` cho phép regression cadence/guard.
- Accepted result đi qua stable `creature.transition.ecology_prey_acquired` và apply owner trước khi set `prey_target`/feedback/panic callback.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Pure regression xanh cho nearest/tie, duplicate, invalid, capture, exact 210px boundary, neutral và protected request.
- Transition regression xanh cho HUNTING_PREY 6s.
- Actor regression xanh: captured prey gần bị bỏ, eligible prey xa hơn được chọn; CHASE và neutral Flam không scan.
- Focused harness teardown chờ presentation tween; chạy lại sạch ObjectDB/resource leak.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression và main smoke; ecology validator sạch leak.
- `git diff --check` sạch; final log scan không có script/parse/dependency/node-path error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; scan-local keys không được persist.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- `panic_from_predator`, hunt timeout/contact và `start_wander()` natural-action RNG vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9e; không cần migration.

### Gói tiếp theo

U1.9f tách một natural-action decision nhỏ trong `start_wander()` với injected rolls, ưu tiên grazing entry vì role/profile đã có. Giữ sleep/drink/grazing precedence và RNG call ordering. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
