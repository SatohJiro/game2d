# Contract Player Locomotion — U1.6b

Trạng thái: VERIFIED ngày 2026-10-04  
Owner domain: `systems/player/player_locomotion_state.gd`  
Input/collision/presentation adapter: `scripts/player.gd`

## Mục tiêu và phạm vi

U1.6b tách stamina, sprint, roll và phép tính desired velocity khỏi CharacterBody2D. Pure state không truy cập `Input`, SceneTree, HUD, audio, animation, clock hệ thống hoặc collision. Player vẫn đọc thiết bị, cung cấp current velocity, gọi state, áp result vào `velocity` rồi `move_and_slide()`.

Ngoài phạm vi: attack/capture/build/craft/progression intent, InputMap/remap/gamepad UI, animation redesign và thay đổi balance.

## Ownership và invariant

`PlayerLocomotionState` sở hữu:

- `max_stamina`, `stamina`, `is_sprinting`.
- `is_rolling`, `is_invulnerable`, `roll_timer`, `roll_direction`, `roll_speed`.
- Sprint eligibility/drain, idle regeneration, roll cost/timer/i-frame và acceleration/deceleration.

Invariant:

- Stamina luôn clamp `[0, max_stamina]` qua public mutation/tick.
- Sprint cần hướng di chuyển, held input và stamina lớn hơn 5 trước tick.
- Roll chỉ bắt đầu khi không roll và stamina ít nhất 20; cost commit đúng một lần.
- Roll chiếm quyền velocity trong frame của nó. I-frame kết thúc khi timer còn `<= 0.06s`; roll kết thúc ở `0s` và trả velocity zero.
- `delta <= 0` giữ nguyên state và current velocity.
- Cùng state + input/context cho cùng result.

Các số 24 stamina/s, 18 regen/s, cost 20, duration 0.32s, speed 380, acceleration 1200 và deceleration 900 là balance prototype của G01. U5 hoặc balance package phải chuyển chúng sang typed tuning data.

## Public contract

### `PlayerMovementInput`

Snapshot gồm `move_direction` và `sprint_held`. Constructor clamp vector dài hơn một về normalized. Adapter hiện đọc WASD/arrow và Shift theo behavior cũ. Roll press vẫn là discrete command từ `_input`, sau đó gọi `try_start_roll(direction)`.

### `PlayerLocomotionState`

- `tick(delta, input, current_velocity, move_speed, sprint_speed, movement_multiplier, stamina_regen_multiplier) -> PlayerLocomotionTickResult`.
- `try_start_roll(direction) -> bool` commit hoặc từ chối atomic.
- `set_stamina`, `set_max_stamina`, `restore_full_stamina`.

Needs chỉ cung cấp hai multiplier, không chia sẻ ownership field. Current velocity là input rõ ràng để bảo toàn attack recoil, sphere recoil và combat knockback. Khi không có move input, state giảm impulse bằng deceleration cũ; khi có input, nó tiến dần về target velocity. Roll có precedence cao hơn mọi impulse trong thời gian active.

### `PlayerLocomotionTickResult`

Result chứa resolved velocity/direction, sprint/roll/invulnerability state và hai transition `roll_frame`, `roll_ended`. `roll_frame` yêu cầu Player chạy collision/HUD theo early-return cũ, kể cả frame roll vừa kết thúc.

## Compatibility adapter

Các property Player `max_stamina`, `stamina`, `is_sprinting`, `is_rolling`, `is_invulnerable`, `roll_timer`, `roll_direction`, `roll_speed` proxy cùng state. Pet skill, food, stat progression và HUD vì vậy tiếp tục hoạt động mà không có store thứ hai. Code mới phải gọi locomotion API cho mutation.

Thứ tự tick hiện giữ behavior prototype: Needs nhận sprint state của physics frame trước, sau đó locomotion resolve input frame hiện tại. Clock/input unification tương lai phải có replay test trước khi đổi thứ tự vì nó ảnh hưởng rất nhỏ tới thirst drain.

## Save, asset và rollback

- Save/data breaking change: none; save system chưa tồn tại. Save v1 chỉ nên lưu stamina cần thiết, không serialize result/input RefCounted hoặc transient roll frame.
- Asset/provenance: none.
- Rollback: revert commit U1.6b; compatibility properties bảo toàn consumer cũ trong migration.

## Validation và debt

`tools/validate_player_locomotion.gd` kiểm tra regen/clamp, sprint threshold/drain, roll lifecycle/i-frame/end, zero/large delta, deterministic repeat, needs multiplier, external knockback decay và main-scene adapter. Log: `build/checks/player-locomotion-validation.log`.

Chưa kiểm chứng bằng automation: collision obstacle cụ thể, keyboard focus khi modal mở, gamepad/remap và animation visual. Manual visual review vẫn cần cho roll ghost/squash, nhưng presentation không quyết định state.
