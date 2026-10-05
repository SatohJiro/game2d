# Checkpoint triển khai Paloria 3.0

## U1.9j — Drinking-entry decision

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Tách drinking-entry khỏi `start_wander()` bằng pure policy, water/distance snapshot và injected RNG.
- Giữ source guard, distance strict `<320px`, chance strict `<0.25`, duration 3–5 giây, pond direction và natural precedence.
- Không đổi asset, skill, drop, spawn, species catalog hoặc save.

### Kết quả đã triển khai

- Thêm `CreatureDrinkingRequest/Result/Policy`; policy không chứa Node, SceneTree hoặc RNG.
- Stable `creature.transition.ecology_drinking_entry` chỉ chuyển IDLE → DRINKING với duration 3–5 giây.
- Actor chỉ gọi roll sau water/range guard, duration roll sau accepted decision, rồi commit pond direction/presentation sau accepted apply.
- Transient `drinking_roll_count`/`drinking_duration_roll_count` khóa short-circuit contract.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused regression xanh cho 319.999/320px, 0.249999/0.25, missing water, protected/invalid request và duration range.
- Actor regression xanh cho DRINKING 5 giây, normalized pond direction, capture guard, stale result và missing-water RNG guard.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression gồm drinking và main smoke.
- Final ecology log sạch ObjectDB/resource leak.
- `git diff --check` và final log scan được yêu cầu sạch trước commit.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; request/result/counters đều transient.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- Natural precedence sleep → drink → grazing → wander và RNG short-circuit giữ nguyên.
- Slime/Mushroom/Beast/Dragon typed definitions cùng skill/drop catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9j; không cần migration.

### Gói tiếp theo

U1.9k mở rộng typed `CreatureDefinition` cho riêng Slime và runtime stat/behavior adapter, giữ legacy attack/drop/ecology compatibility. Không migrate Mushroom/Beast/Dragon hay skill/drop trong cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
