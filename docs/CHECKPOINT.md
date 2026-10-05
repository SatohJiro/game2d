# Checkpoint triển khai Paloria 3.0

## U1.9h — Predator-threat panic callback

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Đưa `panic_from_predator()` qua transition owner.
- Giữ threat target, FLEE 4 giây, floating text, shake audio và CAPTURING/FLEE guards.
- Không đổi hunt selection/lifecycle, sleep/drink, asset, skill, drop, spawn, species catalog hoặc save.

### Kết quả đã triển khai

- Thêm stable event `creature.transition.ecology_predator_threat`, yêu cầu target hợp lệ và trả `TargetAction.SET`.
- Accepted callback vào FLEE 4 giây qua apply owner; presentation chỉ chạy sau accepted apply.
- FLEE/CAPTURING/invalid predator fail closed; repeated result bị from-state stale guard từ chối.
- Tăng teardown margin của ecology validator từ 1,25 lên 1,5 giây vì baseline ngày 2026-10-06 tái hiện race với FloatingText callback 1,12 giây.

### Validation hiện tại

- Baseline assertions xanh nhưng full gate đỏ do ecology fixture báo 2 ObjectDB/1 resource leak không ổn định ở teardown 1,25 giây.
- Focused ecology validator sau thay đổi xanh và sạch leak cho policy/actor predator threat.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression gồm predator threat và main smoke.
- Ecology validator cùng final log sạch ObjectDB/resource leak sau teardown margin 1,5 giây.
- `git diff --check` và final log scan được yêu cầu sạch trước commit.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; stable event và bool callback result đều transient.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- Sleep/drink selection và non-Flam typed catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9h; không cần migration.

### Gói tiếp theo

U1.9i tách sleep-entry decision trong `start_wander()` bằng injected RNG và transition owner, giữ sleep chance/duration cùng RNG short-circuit ordering. Không migrate drinking hoặc species catalog cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
