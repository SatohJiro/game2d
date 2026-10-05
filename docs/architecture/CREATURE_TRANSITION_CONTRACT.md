# U1.8 — Creature transition contract

Trạng thái: U1.8b `VERIFIED` ngày 2026-10-04; U1.8c lifecycle closure `VERIFIED` ngày 2026-10-05.

Pure domain: `systems/creature/creature_transition_*.gd`
Actor adapter: `scripts/creature.gd`

## Mục tiêu và phạm vi

U1.8b tạo owner duy nhất cho năm block transition thuộc lát cắt IDLE/WANDER/SUSPICIOUS/CHASE-loss. Pure policy quyết định state đích, timer, stable reason và target action; actor adapter kiểm tra result còn mới trước khi mutate.

Ngoài phạm vi: quyết định random SLEEP/DRINKING/GRAZING, FLEE lifecycle, predator-prey, charge, skill/drop, damage reaction, capture restore và persistent AI state.

## Stable state và event IDs

State IDs trong contract: `creature.state.idle`, `.wander`, `.suspicious`, `.alert`, `.chase`.

Event IDs:

| Event | From → to | Timer | Target |
|---|---|---:|---|
| `creature.transition.idle_wander` | IDLE → WANDER | injected 2,0–4,0 | KEEP |
| `creature.transition.wander_complete` | WANDER → IDLE | injected 1,5–3,5 | KEEP |
| `creature.transition.suspicion_timeout` | SUSPICIOUS → ALERT/WANDER | 0,40/2,0 | KEEP/CLEAR |
| `creature.transition.chase_target_lost` | CHASE → IDLE | 1,0 | CLEAR |
| `creature.transition.chase_out_of_range` | CHASE → IDLE | 2,0 | CLEAR |

Suspicion result reason tách thành `creature.transition.suspicion_confirmed` hoặc `creature.transition.suspicion_lost`. Display text không làm identity.

## Request và result

`CreatureTransitionRequest` gồm current state ID, event ID, condition flag, target presence/distance, night-raider flag, injected timer và protected flag. Không chứa Node, Callable, SceneTree, tween hoặc RNG.

`CreatureTransitionResult.Status`: `CHANGED`, `NO_CHANGE`, `INVALID_REQUEST`, `PROTECTED`. Result chứa from/to state, stable reason, next timer và target action `KEEP | CLEAR | SET`. `SET` không chứa Node trong pure result; actor adapter chỉ commit khi nhận một target override còn hợp lệ.

## U1.8c — basic lifecycle closure

U1.8c mở rộng cùng request/result/apply owner cho:

- perception entry vào SUSPICIOUS/ALERT, commit state, timer và selected target trong một accepted apply;
- timeout SLEEP, DRINKING, GRAZING và ALERT;
- FLEE hoàn tất hoặc mất target;
- capture/ownership rejection thoát CAPTURING về CHASE khi còn player target, ngược lại về IDLE.

CAPTURING vẫn là protected state cho mọi event ngoài `creature.transition.capture_rejected`. Presentation suspicion/alert, drinking heal/text, flee text và capture-failure feedback chỉ chạy sau accepted apply. Result stale, protected hoặc thiếu target cho `SET` không mutate và không phát presentation.

Policy deterministic và fail closed:

1. Null/empty ID → `INVALID_REQUEST`.
2. Protected → `PROTECTED`.
3. Condition false hoặc state/event không khớp → `NO_CHANGE`.
4. Injected timer phải dương và finite.
5. Suspicion xác nhận khi target hợp lệ và distance `<140`; biên 140 mất dấu.
6. Night raider bỏ qua leash; creature thường rời CHASE khi distance `>450`.

## Apply boundary và stale-result guard

`apply_creature_transition()` là writer duy nhất cho state/timer/target của năm block đã migrate. Nó chỉ apply khi:

- result là `CHANGED`;
- actor chưa defeated, CAPTURING hoặc STUNNED;
- current stable state vẫn bằng `from_state_id`;
- state đích thuộc mapping được hỗ trợ.

Mỗi accepted apply tăng `transition_apply_count`. Apply lại cùng result sau khi state đã đổi trả false, không tăng count. Đây là guard chống result cũ ghi đè state mới; count transient chỉ phục vụ regression/telemetry.

Presentation alert được tách vào `present_alert_feedback()`. SUSPICIOUS-confirmed apply state trước rồi mới chạy tween/audio/howl.

## Writer metric

Trước U1.8b có 5 block assignment trực tiếp trong lát cắt: WANDER complete, SUSPICIOUS lost/confirmed branch, CHASE missing target, CHASE leash và IDLE default wander. Sau U1.8b cả 5 gọi resolve/apply boundary; direct assignment block trong lát cắt là 0.

Ba callback fireball/spore/melee từng ghi `state = CHASE` trực tiếp sau `await`. Chúng dùng chung `finish_legacy_attack_recovery()`, chỉ recover nếu actor vẫn ở ATTACK và chưa defeated/CAPTURING/STUNNED. Skill execution vẫn legacy và thuộc U1.9.

## Writer còn legacy và owner kế tiếp

- U1.9a CreatureDefinition/behavior profile: random entry SLEEP/DRINKING/GRAZING và species parameters.
- U1.9b skill execution: TELEGRAPH_CHARGE/CHARGING/STUNNED, species attack start/recovery và projectile/melee skill writers.
- U1.9d thêm `creature.transition.ecology_damage_panic`: accepted ecology result vào FLEE 3.5 giây qua apply owner, giữ threat target; invalid timer/protected lifecycle không mutate.
- U1.9e thêm `creature.transition.ecology_prey_acquired`: accepted selection vào HUNTING_PREY 6 giây qua apply owner; `prey_target` chỉ set sau accepted transition.
- U1.9f thêm `creature.transition.ecology_grazing_entry`: chỉ IDLE vào GRAZING với injected duration 2.5–4.0 giây; protected/stale/wrong-source result không mutate.
- U1.9g thêm `creature.transition.ecology_hunt_aborted` và `creature.transition.ecology_hunt_contact`: chỉ HUNTING_PREY → IDLE với timer tương ứng 2/3 giây; `prey_target` chỉ clear sau accepted apply và stale/protected result không mutate.
- U1.9h thêm `creature.transition.ecology_predator_threat`: target hợp lệ vào FLEE 4 giây và set threat target; FLEE/CAPTURING/invalid target cùng stale/protected result không mutate.
- U1.9i thêm `creature.transition.ecology_sleep_entry`: chỉ IDLE → SLEEP với injected duration 6–11 giây qua actor adapter; wrong-source/stale/protected result không mutate.
- U1.9c ecology/drop: pack howl, predator/prey HUNTING_PREY/FLEE, prey defeat/drop và damage-reaction CHASE/FLEE.
- Capture entry `CAPTURING` tiếp tục thuộc capture adapter U1.7; rejection/restore đã qua lifecycle owner. Defeat/despawn tiếp tục thuộc combat/capture committed-result boundary.

Trong scope U1.8c có 10 direct writer block trước migration: 2 perception entry, 6 timed lifecycle exit và 2 capture rejection/restore. Sau migration còn 0 block trong scope; các writer còn lại được phân loại cụ thể sang U1.9 hoặc giữ ở committed combat/capture owner hiện hữu.

## Compatibility, save, asset và rollback

- Gameplay threshold/timer/target-clear behavior của năm block giữ nguyên.
- Save/data breaking change: none; request/result/count đều transient.
- Asset/provenance: none.
- Rollback: revert package U1.8c rồi U1.8b nếu cần; không cần migration.

## Validation và giới hạn

`tools/validate_creature_perception.gd` kiểm tra deterministic result, condition false, timer injection, suspicion boundary 139/140, perception entry/duplicate guard, natural timeout, FLEE target loss, ALERT mất target, capture rejection, target action, chase lost/leash/night raid, protected/unknown event, actor apply, stale result apply-once và legacy attack recovery guard.

Full gate tiếp tục chạy perception, transition, capture regression và main smoke. Manual test còn cần cho alert VFX/howl sau suspicion, wander timing, leash và attack bị capture/stun giữa animation.
