# Checkpoint triển khai Paloria 3.0

## U1.6c — Player action input boundary

Trạng thái: VERIFIED ngày 2026-10-04; package branch `work/u1.6c-action-input`. U1.6 Player components đạt gate đã định nghĩa.

### Kết quả

- Thêm `PlayerActionIntent` với 14 stable action ID `player.action.*` và typed payload cho slot/build target/aim.
- `PlayerActionInputMapper` chuyển InputEvent thành intent; release, echo và unknown event trả no-op.
- `PlayerActionPolicy` thuần giữ build/modal/roll guard; Player chỉ dispatch sang handler legacy.
- Build left/right/Escape giữ precedence trước capture/attack.
- Held left attack cũng đi qua intent nhưng vẫn sampled trong physics để giữ cadence/cooldown.
- Sửa lệch README/runtime: Q giờ ném cầu rõ ràng; built-in `ui_focus_next` cũ vẫn được giữ làm compatibility.
- Handler capture/build/craft/pet/progression không bị migrate trong package này.
- `player.gd` giảm từ 1.099 xuống 1.076 dòng; nhánh physical-key mapping/policy đã rời coordinator.

Contract đầy đủ: `docs/architecture/PLAYER_ACTION_CONTRACT.md`.

### Validation

`tools/check_project.ps1` đạt:

- Documentation và asset inventory/action gate.
- 166/166 asset; provenance/action không đổi.
- Editor load, content, inventory, combat, needs, locomotion, player-action và 120-frame main smoke.
- Action regression: toàn bộ key/mouse mapping, Q + compatibility action, build precedence, release/echo/unknown, pet slot payload, deterministic repeat, modal/build/roll guard và Player adapter.
- Log mới: `build/checks/player-actions-validation.log`.

### Compatibility và giới hạn

- Save/data breaking change: none; intent là transient.
- Asset/provenance: none.
- Key cũ giữ nguyên; Q được bổ sung đúng tài liệu, compatibility `ui_focus_next` không bị xóa.
- Chưa có InputMap riêng, remap/gamepad/device prompt; thuộc U3.
- Dispatcher return accepted route, chưa phải domain success result.
- Capture/build/craft/pet/progression handler vẫn mutate state trực tiếp trong Player và được tách theo module sau.
- Modal focus/click-through và held-key interaction cần manual editor playtest.
- Rollback bằng revert commit U1.6c.

### Gói tiếp theo

U1.7a tạo pure deterministic CaptureRequest/CaptureResult/CaptureResolver và migrate phép tính/roll của WildCreature. Giữ animation, inventory sphere, roster/trait và despawn legacy qua adapter; không gộp toàn bộ capture lifecycle trong một commit.

### Audit đầu vào U1.7a đã ghi nhận

- Base chance hiện là `lerp(0.95, 0.25, hp_ratio)`, clamp `[0.15, 0.95]`.
- Final chance nhân sphere multiplier + additive back-strike/sleep multiplier, clamp `[0.10, 0.98]`, rồi so `randf() <= chance`.
- Sleep bonus hiện không bao giờ chạy vì state bị đổi sang CAPTURING trước khi kiểm tra SLEEP; resolver mới phải nhận pre-capture status và có regression.
- Back strike phụ thuộc facing vector dot throw direction > 0.25.
- Capture animation chờ nhiều tween/timer trước RNG; U1.7a phải resolve deterministic trước presentation nhưng chỉ commit outcome đúng một lần sau presentation.
- Player inventory sphere selection/consume, random rarity/trait, party append và creature despawn nằm ngoài U1.7a.

## Lịch sử

- U1.6b: pure locomotion/stamina/sprint/roll.
- U1.6a: pure Player needs state/snapshot.
- U1.5: deterministic combat request/result.
- U1.4: inventory transaction + chest capacity.
- U1.3: typed domain definitions.
- U1.2: stable wood adapter.
- U1.1: stable IDs/registry.
