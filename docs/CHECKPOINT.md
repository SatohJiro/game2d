# Checkpoint triển khai Paloria 3.0

## U1.9c — Flam deterministic defeat drop

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- Tách quyết định drop của đúng một Flam canary khỏi animation/spawn bằng request/result thuần.
- Giữ quantity/range, elite bonus, defeat idempotency và capture exclusion hiện hữu.
- Không đổi EXP, asset, balance, collision, spawn table, skill, save schema hoặc toàn bộ species catalog.

### Kết quả đã triển khai

- Thêm `CreatureDropRequest`, `CreatureDropResult`, `CreatureDropResolver`; RNG count sinh ngoài resolver và được inject.
- Stable `creature.flam` + `item.pal_ore` đi xuyên request/result đến `DroppedItem.item_id`.
- `defeat_drops_committed` và result identity guard bảo đảm commit tối đa một lần.
- Capture active trả `CAPTURE_BLOCKED`; living/invalid/duplicate fail closed và không spawn.
- Normal giữ 1–2 primary node; elite/alpha giữ 3–5 primary node cộng một bonus stack count 2–4.
- Bốn species còn lại tiếp tục legacy spawn để tránh thay đổi content chưa có typed definition.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused resolver regression xanh cho normal/elite, domain/range invalid, living, capture, duplicate và deterministic injected request.
- Actor regression xanh cho typed Flam reference, stable spawned item ID, legacy quantity và duplicate commit không spawn thêm.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression gồm drop validator mới và main smoke.
- `git diff --check` sạch; final log scan không có script/parse/dependency/node-path error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; result là runtime value object, không serialize Node/Resource.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- EXP reward, non-Flam drop, predator/prey targeting, grazing/FLEE và burn defeat path vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert package U1.9c; không cần migration.

### Gói tiếp theo

U1.9d chọn đúng một ecology ownership boundary nhỏ cho Flam, ưu tiên pure role/decision không chứa Node hoặc RNG ẩn. Không migrate thêm skill/drop catalog cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
