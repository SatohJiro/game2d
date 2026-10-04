# Checkpoint triển khai Paloria 3.0

## U1.6a — Player needs state boundary

Trạng thái: VERIFIED ngày 2026-10-04; đã tích hợp vào `main` qua package branch `work/u1.6a-player-needs`.

### Kết quả

- `PlayerNeedsState` là nguồn sự thật duy nhất cho hunger, thirst, body temperature và timed food buff.
- Tick thuần nhận `delta`, sprint, near-heat; không truy cập Input, SceneTree, HUD, audio hoặc RNG.
- Thêm detached `PlayerNeedsSnapshot` và transition `PlayerNeedsTickResult.buff_expired`.
- Thay identity buff bằng `needs.buff.*`; text tiếng Việt chỉ còn ở display/legacy adapter.
- Player giữ property legacy proxy cùng state; không tạo store song song.
- Pond, food, respawn, movement modifier và stamina regen đã route qua needs API.
- HUD lấy một snapshot rồi render scalar; heat-source scan vẫn thuộc coordinator.
- `player.gd` giảm từ 1.123 xuống 1.115 dòng; responsibility quan trọng đã chuyển sang ba pure type thay vì chỉ dịch dòng.

Contract đầy đủ: `docs/architecture/PLAYER_NEEDS_CONTRACT.md`.

### Validation

`tools/check_project.ps1` đạt:

- Documentation và asset inventory/action gate.
- 166/166 asset; provenance/action không đổi.
- Editor load, content, inventory, combat, player-needs regression và 120-frame main smoke.
- Needs regression: deterministic repeat, normal/sprint rate, zero/large delta, clamp, temperature, multipliers, restoration, expiry đúng một lần, detached snapshot và Player compatibility adapter.
- Log mới: `build/checks/player-needs-validation.log`.

### Compatibility và giới hạn

- Save/data breaking change: none; save system chưa tồn tại. U1.11 phải lưu scalar + stable buff ID.
- Asset/provenance: none.
- Public legacy fields `hunger`, `thirst`, `body_temperature`, `food_buff_name`, `food_buff_timer` vẫn hoạt động qua proxy.
- Stamina, sprint, roll, input polling, velocity, animation và collision còn ở Player.
- Balance rate/threshold còn hardcode trong needs state; G02/U5 sẽ chuyển sang typed tuning data.
- Group scan nguồn nhiệt mỗi physics frame chưa tối ưu; chuyển sang world influence/spatial service sau.
- Pause UI tương tác chưa có regression riêng; zero delta/no tick đã được kiểm tra ở pure state.
- Rollback bằng revert commit U1.6a.

### Gói tiếp theo

U1.6b tách input movement snapshot và locomotion/stamina/roll calculation theo contract thuần, giữ CharacterBody2D làm collision adapter. Không trộn attack, build, crafting, progression hoặc UI redesign. Bắt đầu bằng audit `_input`, roll và `_physics_process`, sau đó chạy gate baseline trước khi sửa.

## Lịch sử

- U1.5: deterministic combat request/result.
- U1.4: inventory transaction + chest capacity.
- U1.3: typed domain definitions.
- U1.2: stable wood adapter.
- U1.1: stable IDs/registry.
