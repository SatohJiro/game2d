# Contract Player Action Input — U1.6c

Trạng thái: VERIFIED ngày 2026-10-04  
Intent/mapping/policy: `systems/player/player_action_*.gd`  
Coordinator adapter: `scripts/player.gd`

## Mục tiêu và ranh giới

U1.6c biến input vật lý thành typed intent trước khi gọi gameplay handler. Mapper chỉ đọc `InputEvent`; policy chỉ đọc context boolean; cả hai không sửa inventory, HP, UI hoặc world Node. Player coordinator dispatch intent sang handler legacy hiện tại.

Ngoài phạm vi: InputMap/remap/gamepad, capture probability, recipe/building/progression domain, UI redesign và held movement snapshot đã thuộc U1.6b.

## Stable action IDs và payload

| Action ID | Input hiện tại | Payload/handler adapter |
|---|---|---|
| `player.action.attack` | giữ chuột trái ngoài build | `aim_direction` → `perform_attack` |
| `player.action.roll` | Space | `try_combat_roll` |
| `player.action.interact` | E | `try_interact` |
| `player.action.capture_throw` | chuột phải, Q, compatibility `ui_focus_next` | `throw_pal_sphere` |
| `player.action.toggle_crafting` | C | HUD toggle |
| `player.action.toggle_character` | P | HUD toggle |
| `player.action.build_start` | B | legacy target ID `wood_fence` |
| `player.action.build_place` | chuột trái khi build | `place_current_building` |
| `player.action.build_cancel` | chuột phải/Escape khi build | `cancel_build_mode` |
| `player.action.pet_select` | 1/2/3 | zero-based `slot_index` |
| `player.action.pet_command` | R | `command_pets` |
| `player.action.pet_skill` | G | `activate_partner_skill` |
| `player.action.use_food` | F | `eat_berry`/food priority legacy |
| `player.action.use_elixir` | H | `use_pal_elixir` |

Action ID là identity ổn định, không dùng label tiếng Việt hoặc phím làm khóa. `wood_fence` còn là payload legacy vì building catalog chưa migrate; package building phải đổi nó qua stable content ID với adapter.

README trước đây ghi Q nhưng runtime chỉ gọi built-in `ui_focus_next`, thường là Tab. U1.6c thêm Q rõ ràng và giữ action cũ để không cắt compatibility.

## Mapping và precedence

`PlayerActionInputMapper.map_event(event, is_building)` trả một intent hoặc `ACTION_NONE`:

1. Khi build mode, chuột trái map place; chuột phải/Escape map cancel và thắng mọi mapping khác.
2. Ngoài precedence trên, right mouse/Q/`ui_focus_next` map capture throw.
3. Key release, key echo và event không biết trả no-op.
4. Held left mouse attack được sampled trong physics để giữ cadence/cooldown, nhưng vẫn tạo `ACTION_ATTACK` trước dispatch.

`PlayerActionPolicy.is_allowed(intent, is_building, modal_open, is_rolling)`:

- place/cancel chỉ hợp lệ khi build mode;
- roll bị chặn bởi build hoặc modal;
- attack bị chặn bởi build, modal hoặc active roll;
- handler domain khác giữ guard nội bộ hiện tại cho tới package sở hữu nó.

`Player.dispatch_action_intent` là coordinator adapter duy nhất. Return `false` khi intent invalid/blocked/unknown, `true` khi route được nhận; return này chưa khẳng định domain handler thành công.

## Compatibility, save và asset

- Key hiện có giữ nguyên; Q được sửa đúng theo README, `ui_focus_next` cũ vẫn chạy.
- Save/data breaking change: none. Intent là transient và không được serialize.
- Asset/provenance: none.
- Rollback: revert commit U1.6c; handler signatures không đổi.

## Validation và debt

`tools/validate_player_actions.gd` kiểm tra mọi key/mouse mapping, build precedence, Q và action compatibility, release/echo/unknown no-op, pet payload, deterministic mapping, modal/build/roll policy và main-scene dispatch adapter. Log: `build/checks/player-actions-validation.log`.

Debt còn lại:

- Handler craft/build/capture/pet/progression vẫn mutate domain trực tiếp trong Player.
- Input chưa dùng project action names cho remap/gamepad; U3 phải thay physical-key mapper qua compatibility adapter.
- Modal focus/click-through và held input cần manual playtest trong editor.
