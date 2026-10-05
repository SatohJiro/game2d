# Checkpoint triển khai Paloria 3.0

## U1.9d — Creature ecology damage-panic policy

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- Tách đúng low-HP prey panic sau damage thành pure decision và transition-owned mutation.
- Giữ strict threshold `<35%`, duration 3.5 giây, threat target, lifecycle guard và feedback hiện hữu.
- Không đổi RNG ordering, predator scan, grazing/hunting, asset, drop, skill, spawn hoặc save.

### Kết quả đã triển khai

- Thêm `CreatureEcologyRequest`, `CreatureEcologyResult`, `CreatureEcologyPolicy` không chứa Node/RNG.
- Stable event `creature.transition.ecology_damage_panic` đi qua `CreatureTransitionPolicy` và `apply_creature_transition()`.
- Typed-neutral Flam trả `NO_CHANGE`; legacy Slime/Mushroom prey vẫn panic khi đủ điều kiện.
- Defeated/enraged/HP >=35% trả `NO_CHANGE`; capture trả `PROTECTED`; invalid ID/HP fail closed.
- Floating text chỉ chạy sau accepted apply; không còn direct `state = FLEE` trong damage-panic block.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused pure regression xanh cho threshold boundary, roles, defeated/enraged/capture, invalid input và stable event/duration.
- Transition regression xanh cho legacy source state, target preservation và invalid timer.
- Actor regression xanh cho neutral Flam và prey Slime compatibility.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression gồm ecology validator mới và main smoke.
- `git diff --check` sạch; final log scan không có script/parse/dependency/node-path error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; request/result là runtime value object.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- Predator group scan/selection, `panic_from_predator`, grazing RNG và hunt timeout/contact vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9d; không cần migration.

### Gói tiếp theo

U1.9e tách deterministic predator/prey candidate selection khỏi group scan cho một canary, giữ scan cadence 2.0–3.5s và hunt distance 210px. Không migrate grazing hoặc skill/drop catalog cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
