# Checkpoint triển khai Paloria 3.0

## U1.9f — Natural-action grazing decision

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- Tách grazing-entry decision bằng injected roll và typed prey role.
- Giữ sleep → drink → grazing → wander precedence, số/thứ tự RNG call, strict chance `<0.22` và duration 2.5–4.0s.
- Không migrate sleep/drink, hunt contact, asset, skill, drop, spawn hoặc save.

### Kết quả đã triển khai

- Thêm `CreatureGrazingRequest/Result/Policy` không chứa Node/RNG.
- Stable `creature.transition.ecology_grazing_entry` chỉ chuyển IDLE → GRAZING qua apply owner.
- Actor chỉ gọi grazing roll cho prey và duration roll sau accepted decision; hai transient counter khóa short-circuit contract.
- Typed-neutral Flam trả `NO_CHANGE`; Slime/Mushroom prey giữ probability và duration cũ; CAPTURING trả `PROTECTED`.
- Presentation chỉ chạy sau accepted transition; fallback wander giữ nguyên.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Pure regression xanh cho 0.219999/0.22 boundary, neutral/prey/protected và invalid roll.
- Transition regression xanh cho IDLE-only entry và injected duration.
- Actor regression xanh cho Flam neutral, Slime accepted GRAZING duration 4.0 và capture guard.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression gồm grazing và main smoke; validator sạch leak.
- `git diff --check` sạch; final log scan không có script/parse/dependency/node-path error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; counters/request/result đều transient.
- Asset/provenance: không thêm/sửa asset; baseline vẫn 166 quarantine/unknown, 69 runtime P0.
- Sleep/drink selection, predator panic callback, hunt timeout/contact và non-Flam typed catalog vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9f; không cần migration.

### Gói tiếp theo

U1.9g tách hunt lifecycle timeout/contact exit qua transition owner, giữ prey damage multiplier 0.7, distance `<42px`, timers 2s/3s và presentation. Không mở rộng species catalog cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
