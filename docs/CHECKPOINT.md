# Checkpoint triển khai Paloria 3.0

## U1.9g — Hunt lifecycle closure

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- Đưa HUNTING_PREY invalid-target/timeout và contact exit qua transition owner.
- Giữ speed ×1.05, contact strict `<42px`, damage `int(attack_power * 0.7)`, abort 2 giây, contact recovery 3 giây và feedback.
- Không đổi sleep/drink, predator panic callback, asset, skill, drop, spawn hoặc save.

### Kết quả đã triển khai

- Thêm stable events `creature.transition.ecology_hunt_aborted` và `creature.transition.ecology_hunt_contact`, chỉ nhận source HUNTING_PREY.
- Actor resolve/apply qua lifecycle owner; ecology `prey_target` chỉ clear sau accepted transition, regular combat target được giữ nguyên.
- Contact damage vẫn được resolve trước transition commit như behavior cũ; presentation chỉ chạy sau accepted apply.
- Stale result bị từ chối bằng from-state guard và không tăng apply count.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused ecology regression xanh cho policy abort/contact, wrong-source/protected, actor invalid prey, timeout, contact damage/recovery và repeated stale result.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression gồm hunt lifecycle và main smoke.
- Validator chờ đủ vòng đời FloatingText rồi teardown; final log không còn ObjectDB/resource leak.
- `git diff --check` và final log scan được yêu cầu sạch trước commit.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; events và actor helper đều transient.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- `panic_from_predator()`, sleep/drink selection và non-Flam typed catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9g; không cần migration.

### Gói tiếp theo

U1.9h đưa predator-threat panic callback qua transition owner, giữ target, FLEE 4 giây, text/audio và capture/FLEE guards. Không mở rộng sleep/drink hoặc species catalog cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
