# U1.8b — Creature transition contract

Trạng thái: `VERIFIED` ngày 2026-10-04

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

`CreatureTransitionResult.Status`: `CHANGED`, `NO_CHANGE`, `INVALID_REQUEST`, `PROTECTED`. Result chứa from/to state, stable reason, next timer và target action `KEEP | CLEAR`.

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

## Writer còn legacy

- Timed FLEE, DRINKING, GRAZING, SLEEP, ALERT, charge và stun state handlers.
- `trigger_suspicion`, `trigger_alert`, pack/ecosystem, damage reaction và capture rejection.
- Species attack start, prey hunt, defeat/despawn và velocity ownership.

U1.8c phải đóng các lifecycle/basic-state writer phù hợp trước khi U1.8 được đánh dấu hoàn tất. Combat skill/drop và ecology-specific transitions có thể chuyển tiếp U1.9 nếu owner được ghi rõ.

## Compatibility, save, asset và rollback

- Gameplay threshold/timer/target-clear behavior của năm block giữ nguyên.
- Save/data breaking change: none; request/result/count đều transient.
- Asset/provenance: none.
- Rollback: revert commit U1.8b; không cần migration.

## Validation và giới hạn

`tools/validate_creature_perception.gd` kiểm tra deterministic result, condition false, timer injection, suspicion boundary 139/140, target action, chase lost/leash/night raid, protected/unknown event, actor apply, stale result apply-once và legacy attack recovery guard.

Full gate tiếp tục chạy perception, transition, capture regression và main smoke. Manual test còn cần cho alert VFX/howl sau suspicion, wander timing, leash và attack bị capture/stun giữa animation.
