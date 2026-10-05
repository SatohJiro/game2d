# Checkpoint triển khai Paloria 3.0

## U1.8c — Creature lifecycle closure

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- Basic lifecycle transition có một pure resolver và một actor apply owner.
- Perception entry commit state/target/timer nguyên tử; stale/protected result không mutate.
- Presentation chỉ chạy sau accepted apply.
- Giữ nguyên perception cadence 0,20 giây, threshold, timer, balance và scene hierarchy.

### Kết quả đã triển khai

- Thêm stable state/event cho perception entry, SLEEP/DRINKING/GRAZING/ALERT/FLEE timeout và capture rejection.
- `TargetAction.SET` giữ pure result không chứa Node; adapter chỉ nhận target override hợp lệ tại apply boundary.
- CAPTURING chỉ cho phép explicit capture-rejection exit; event khác vẫn protected.
- Drinking heal/text, flee text, alert/suspicion feedback và capture failure presentation chạy sau accepted apply.
- Writer metric trong scope: 10 direct block trước migration, 0 sau migration.

### Validation hiện tại

- Focused Creature validator đạt perception cadence/policy, perception entry, duplicate guard, natural timeout, FLEE target loss, ALERT target loss, capture rejection, protected/stale apply và legacy attack recovery.
- Full `tools/check_project.ps1` đạt sau package: documentation/asset gates, editor load, mọi domain regression và main-scene smoke xanh.
- `git diff --check` sạch; log scan không có script/parse/dependency/runtime error hoặc resource leak.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; state/event/result và transition count đều transient.
- Asset/provenance: không thêm hoặc sửa asset; 166 asset giữ nguyên trạng thái inventory/action hiện hữu.
- Balance, animation, collision, spawn và scene hierarchy không đổi.
- Manual test còn cần cho alert howl, drinking heal feedback, FLEE completion và capture rejection visual.
- Random natural-state entry chuyển U1.9a; charge/species attack sang U1.9b; pack/predator-prey/drop/damage-reaction writer sang U1.9c.
- Rollback: revert package U1.8c; không cần migration.

### Gói tiếp theo

U1.9a audit và tạo lát cắt CreatureDefinition/behavior profile typed. Không migrate skill execution hoặc drop/ecology trong cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.

## Hướng sản phẩm phải giữ

- AI state không lưu Node/ObjectID làm persistent identity, sẵn sàng cho chunk unload U2.
- Paloria Luminous Town vẫn là initiative U2–U4; content phải nguyên bản và có license/provenance.
- Asset admission mới còn bị chặn vì `game-dev` CLI chưa có trong PATH.
