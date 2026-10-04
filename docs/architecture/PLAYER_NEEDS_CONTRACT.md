# Contract Player Needs — U1.6a

Trạng thái: VERIFIED ngày 2026-10-04  
Owner domain: `systems/player/player_needs_state.gd`  
Coordinator/compatibility adapter: `scripts/player.gd`

## Mục tiêu và phạm vi

U1.6a tách hunger, thirst, body temperature và một timed food buff khỏi vòng physics của Player. State thuần không truy cập `Input`, `SceneTree`, Node, HUD, audio hoặc RNG. Stamina, sprint, roll, velocity, dò nguồn nhiệt và sử dụng item vẫn do Player sở hữu trong package này.

Invariant:

- `hunger` và `thirst` luôn nằm trong `[0, max]` sau API mutation/tick.
- Cùng state + `delta` + context tạo cùng snapshot/result.
- `delta <= 0` không đổi state; coordinator thực thi pause bằng cách không tick physics/game clock.
- Một buff active tại một thời điểm; thay buff ghi đè ID và duration.
- Hết hạn chuyển về `BUFF_NONE` và `buff_expired=true` đúng một tick.
- Text hiển thị không còn là identity domain; identity dùng `needs.buff.*`.

## Public contract

### `PlayerNeedsState`

State:

- `max_hunger`, `hunger`, `max_thirst`, `thirst`, `body_temperature`.
- `buff_id: StringName`, `buff_time_remaining`.

Stable buff IDs:

| ID | Effect hiện tại | Display adapter legacy |
|---|---|---|
| `needs.buff.stamina_regen` | stamina regen ×1.5 | Bồi Bổ Thể Lực (x1.5 hồi) |
| `needs.buff.warmth` | warm toward 37°C | Giữ Nhiệt Ấm Áp |
| `needs.buff.speed` | movement ×1.15 | Tăng Tốc Chạy (+15%) |
| `needs.buff.slow_hunger` | hunger drain 0.14/s | No Lâu Giảm Đói |

Mutation/query API:

- `tick(delta, is_sprinting, near_heat) -> PlayerNeedsTickResult`.
- `restore_hunger`, `restore_thirst`, `set_hunger`, `set_thirst`, `set_temperature`.
- `set_buff`, `set_buff_duration`, `clear_buff`.
- `get_movement_multiplier`, `get_stamina_regen_multiplier`.
- `create_snapshot() -> PlayerNeedsSnapshot`.

Các số cân bằng 0.28/0.14 hunger, 0.25/0.45 thirst, 37/23.5°C và tốc độ nhiệt vẫn là prototype do G02 sở hữu; chuyển sang typed tuning Resource trong U5, không tạo catalog trong package refactor này.

### Snapshot/result

`PlayerNeedsSnapshot` là bản sao scalar cho presentation/save adapter; mutation state sau đó không đổi snapshot cũ. `PlayerNeedsTickResult` chứa snapshot sau tick và cờ transition `buff_expired`. Không lưu hai object này như Node hoặc dùng chúng làm identity save.

## Luồng adapter runtime

1. Player dò `heat_sources` và Fire Pet vì đây là SceneTree concern.
2. Player gọi `needs_state.tick(delta, is_sprinting, near_heat)`.
3. Locomotion hiện đọc multiplier từ needs state; stamina vẫn được Player mutate.
4. Food/pond/respawn gọi mutation API thay cho sửa field domain trực tiếp.
5. HUD nhận scalar từ một `PlayerNeedsSnapshot` và chỉ render.

Các property Player `max_hunger`, `hunger`, `max_thirst`, `thirst`, `body_temperature`, `food_buff_name`, `food_buff_timer` là compatibility adapter. Chúng proxy cùng `needs_state`, không tạo store thứ hai. Code mới phải dùng stable buff ID và API state.

## Save, asset và rollback

- Save schema/migration: none; save system chưa tồn tại. U1.11 phải serialize scalar + stable `buff_id`, không serialize RefCounted.
- Asset/provenance: none.
- Rollback: revert commit U1.6a; property adapter giữ scene/consumer cũ trong thời gian migration.

## Validation và giới hạn

`tools/validate_player_needs.gd` kiểm tra deterministic repeat, rate sprint, zero/large delta, clamp, heat, modifier, expiry một lần, snapshot copy và main-scene adapter. `tools/check_project.ps1` lưu log ở `build/checks/player-needs-validation.log`.

Chưa thực hiện: clock service riêng, pause menu regression tương tác, stacking nhiều buff, warning threshold, save/load và data-driven balance. Dò toàn bộ group nhiệt mỗi physics frame là debt của world influence/spatial service.
