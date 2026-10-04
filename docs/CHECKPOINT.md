# Checkpoint triển khai Paloria 3.0

## U1.6b — Player locomotion state boundary

Trạng thái: VERIFIED ngày 2026-10-04; package branch `work/u1.6b-player-locomotion`.

### Kết quả

- Thêm typed `PlayerMovementInput`, pure `PlayerLocomotionState` và `PlayerLocomotionTickResult`.
- State sở hữu stamina, sprint eligibility/drain/regen, roll cost/timer/direction/i-frame và desired velocity.
- Player đọc WASD/arrow/Shift, truyền current velocity + Needs multiplier, áp result vào CharacterBody2D và collision.
- Attack recoil, sphere recoil và combat knockback được bảo toàn qua explicit current velocity; roll có precedence khi active.
- Pet skill, food, stat progression và HUD tiếp tục dùng property Player proxy cùng state, không có store song song.
- Roll presentation/audio/ghost giữ trong Player và không quyết định gameplay state.
- `player.gd` giảm từ 1.115 xuống 1.099 dòng; stamina/sprint/roll mutation đã rời coordinator.

Contract đầy đủ: `docs/architecture/PLAYER_LOCOMOTION_CONTRACT.md`.

### Validation

`tools/check_project.ps1` đạt:

- Documentation và asset inventory/action gate.
- 166/166 asset; provenance/action không đổi.
- Editor load, content, inventory, combat, needs, locomotion và 120-frame main smoke.
- Locomotion regression: regen/clamp, sprint threshold/drain, roll start/cost/i-frame/recovery/end, zero/large delta, deterministic repeat, Needs multiplier, knockback decay và Player adapter.
- Log mới: `build/checks/player-locomotion-validation.log`.

### Compatibility và giới hạn

- Save/data breaking change: none; save system chưa tồn tại.
- Asset/provenance: none.
- Property stamina/sprint/roll cũ trên Player là compatibility proxy; code mới gọi state API.
- Keyboard mapping giữ nguyên và chưa thêm InputMap/gamepad/remap.
- Needs hiện nhận sprint state của physics frame trước để giữ thứ tự prototype.
- Collision obstacle, modal focus và roll visual cần manual playtest; headless smoke chỉ xác nhận runtime sạch.
- Action input, attack/capture/build/craft/progression và presentation vẫn ở Player.
- Balance locomotion vẫn hardcode, sẽ data hóa ở package balance sau.
- Rollback bằng revert commit U1.6b.

### Gói tiếp theo

U1.6c tách discrete action input mapping/routing khỏi Player bằng stable action IDs/typed intent, giữ các domain handler hiện tại làm adapter. Không migrate capture/build/craft logic trong cùng commit. Sau U1.6c bắt đầu U1.7 capture request/result.

## Lịch sử

- U1.6a: pure Player needs state/snapshot.
- U1.5: deterministic combat request/result.
- U1.4: inventory transaction + chest capacity.
- U1.3: typed domain definitions.
- U1.2: stable wood adapter.
- U1.1: stable IDs/registry.
