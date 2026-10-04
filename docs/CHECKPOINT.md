# Checkpoint triển khai Paloria 3.0

## U1.7a — deterministic capture resolution

Trạng thái: VERIFIED ngày 2026-10-04; package branch `work/u1.7a-capture-result`.

### Kết quả

- Thêm pure `CaptureRequest`, `CaptureResult`, `CaptureResolver`.
- Resolver validate target/attempt/defeat/numeric input, tính HP curve, sphere/status/back-strike modifier, clamp chance và so injected roll.
- RNG capture được lấy đúng một lần trước animation; tween/timer không còn quyết định outcome.
- WildCreature snapshot sleep và facing/back-strike trước khi đổi sang CAPTURING.
- Sửa sleep capture bonus trước đây unreachable.
- `capture_attempt_active` và status `ALREADY_CAPTURING` chặn concurrent attempt.
- Commit success/failure chạy đúng một lần sau animation qua `commit_capture_result`.
- Signature Sphere → `attempt_capture(player_ref, multiplier, throw_pos)` được giữ.
- Inventory sphere, roster, trait RNG, party append và despawn ownership vẫn là adapter legacy.

Contract đầy đủ: `docs/architecture/CAPTURE_CONTRACT.md`.

### Validation

`tools/check_project.ps1` đạt:

- Documentation và asset inventory/action gate.
- 166/166 asset; provenance/action không đổi.
- Editor load, content, inventory, combat, Player boundaries, capture và 120-frame main smoke.
- Capture regression: full/low/zero HP, min/max clamp, basic/mega/giga, sleep/back-strike/kết hợp, roll 0/1/equality, invalid/status guard, deterministic repeat, pre-state Creature adapter và concurrent attempt.
- Log mới: `build/checks/capture-validation.log`.

### Compatibility và giới hạn

- Save/data breaking change: none; request/result/active attempt là transient.
- Asset/provenance: none.
- Species ID còn rỗng do legacy species dictionary chưa có typed CreatureDefinition; không tạo ID giả từ display name/index.
- Seeded RNG service chưa có; resolver deterministic bằng injected roll.
- Manual editor test còn cần cho ba shake, fail restore và success despawn visual.
- Player sphere inventory vẫn direct write; miss drop dùng legacy sphere name.
- Capture success vẫn gọi Player roster/trait RNG rồi queue_free creature.
- Rollback bằng revert commit U1.7a.

### Gói tiếp theo

U1.7 được chia tiếp để giữ transaction nhỏ:

- U1.7b: stable sphere item IDs, pure selection và atomic inventory spend/launch/miss-drop adapter.
- U1.7c: PetInstance/roster ownership commit trước wild despawn, trait RNG injection và duplicate guard.
- Sau U1.7 mới chuyển U1.8 perception/FSM.

## Lịch sử

- U1.6: Player needs, locomotion và action input boundaries.
- U1.5: deterministic combat request/result.
- U1.4: inventory transaction + chest capacity.
- U1.3: typed domain definitions.
- U1.2: stable wood adapter.
- U1.1: stable IDs/registry.
