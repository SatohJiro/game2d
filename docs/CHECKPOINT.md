# Checkpoint triển khai Paloria 3.0

## U1.9i — Sleep-entry decision

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Tách sleep-entry khỏi `start_wander()` bằng pure policy, injected RNG và transition owner.
- Giữ peaceful eligibility, strict chance `<0.18`, duration 6–11 giây và sleep → drink → grazing → wander precedence.
- Không migrate drinking, asset, skill, drop, spawn, species catalog hoặc save.

### Kết quả đã triển khai

- Thêm `CreatureSleepRequest/Result/Policy`; policy không chứa Node, SceneTree hoặc RNG.
- Stable `creature.transition.ecology_sleep_entry` chỉ chuyển IDLE → SLEEP qua apply owner.
- Actor chỉ tiêu thụ sleep roll khi không night-raider/enraged và duration roll sau accepted decision.
- Thêm transient counters khóa short-circuit; actor adapter từ chối duration ngoài 6–11 giây.
- Ecology fixture teardown giải phóng fixture/presentation có chủ đích và chờ AudioServer release thay vì dựa vào thời gian sống FloatingText.

### Validation hiện tại

- Baseline assertions xanh nhưng full gate tái hiện teardown leak không ổn định từ ecology fixture cũ.
- Focused ecology validator chạy xanh, sạch leak hai lần liên tiếp sau deterministic teardown.
- Pure regression xanh cho 0.179999/0.18 boundary, night-raider, enraged, protected và invalid request.
- Actor regression xanh cho accepted SLEEP 11 giây, capture guard, stale result và RNG guard.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression gồm sleep và main smoke.
- Final ecology log sạch ObjectDB/resource leak với deterministic fixture/audio teardown.
- `git diff --check` và final log scan được yêu cầu sạch trước commit.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; request/result/counters đều transient.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- Drinking selection và non-Flam typed catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9i; không cần migration.

### Gói tiếp theo

U1.9j tách drinking-entry decision trong `start_wander()` bằng injected RNG/distance snapshot và transition owner, giữ chance, range, direction và natural precedence. Không mở rộng species catalog cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
