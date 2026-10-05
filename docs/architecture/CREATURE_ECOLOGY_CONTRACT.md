# U1.9d — Creature ecology damage-panic contract

## Phạm vi

Package này tách đúng quyết định panic-FLEE sau khi nhận damage. Grazing RNG, predator scan, prey selection, hunting movement/contact và species catalog không migrate trong cùng package.

## Pure policy

`CreatureEcologyRequest` chứa stable species ID, prey role, HP snapshot, defeated/enraged và capture guard. `CreatureEcologyPolicy.resolve_damage_panic()` không truy cập Node, SceneTree, RNG, animation hoặc audio.

Kết quả `CreatureEcologyResult.Status`:

- `PANIC_FLEE`: prey còn sống, không enraged/capture và HP ratio `< 0.35`.
- `NO_CHANGE`: neutral/predator, defeated, enraged hoặc HP ratio `>= 0.35`.
- `PROTECTED`: capture đang hoạt động.
- `INVALID_REQUEST`: species ID sai domain hoặc HP snapshot không hợp lệ.

Accepted result phát stable event `creature.transition.ecology_damage_panic` với duration 3.5 giây. Cùng request luôn cho cùng result và policy không gọi RNG.

## Actor và transition ownership

- `WildCreature` tạo request sau accepted `DamageResult`; typed Flam role tiếp tục được chiếu từ `CreatureBehaviorProfile`, species khác dùng legacy snapshot.
- Actor chuyển ecology result thành `CreatureTransitionRequest`; chỉ `apply_creature_transition()` mutate state/timer.
- Transition giữ threat target, vào `FLEE`, từ chối timer không dương và tôn trọng defeat/stun/capture lifecycle guard hiện hữu.
- Floating text panic chỉ chạy sau accepted transition.

## Compatibility

- Ngưỡng vẫn strict `<35%`; đúng 35% không flee.
- Duration vẫn 3.5 giây; defeated, enraged và capture không flee.
- Flam neutral không flee; Slime/Mushroom prey giữ behavior cũ.
- Không đổi RNG ordering, cadence, distance, damage, drop, skill, spawn, asset hoặc save schema.

## Writer audit còn lại

| Writer | Hiện trạng | Hướng sau |
|---|---|---|
| Damage low-HP panic | pure ecology policy + transition owner | U1.9d verified |
| `check_predator_prey_ecosystem()` | group scan + first-match selection + direct hunt/panic writes | tách deterministic candidate policy |
| `panic_from_predator()` | direct FLEE writer | migrate cùng predator/prey selection |
| `start_wander()` grazing | prey role + injected-by-engine RNG + direct GRAZING writer | natural action policy package |
| Hunt timeout/contact | direct IDLE writer và legacy melee | transition/skill follow-up |

Rollback bằng revert U1.9d; không cần save/data migration.

## U1.9e — Predator/prey selection

`CreatureEcologySelectionPolicy` nhận predator role/state guard và danh sách candidate thuần. Candidate chỉ chứa scan-local key, stable species ID, prey/capture flags và distance; không chứa Node hay ObjectID.

Selection rule:

1. Invalid/null predator request fail closed; blocked state trả `PROTECTED`; non-predator trả `NONE_AVAILABLE` trước group scan ở actor.
2. Bỏ candidate null/invalid, non-prey, capture-active, distance không hữu hạn/âm hoặc `>=210px`.
3. Duplicate scan-local key giữ observation gần nhất.
4. Chọn distance nhỏ nhất; bằng nhau tie-break lexical `candidate_key`, không phụ thuộc thứ tự group.
5. Accepted result phát `creature.transition.ecology_prey_acquired`, duration 6 giây.

Actor giữ map scan-local key → live `WildCreature` chỉ trong lần query. Sau khi result và transition được accept, actor mới set `prey_target`, phát feedback và gọi legacy `panic_from_predator()`. Pack/ecology cadence vẫn 2.0–3.5 giây; policy không gọi RNG.

Writer còn lại sau U1.9e: prey panic callback vẫn direct FLEE; hunt timeout/contact vẫn direct IDLE/melee; grazing/sleep/drink choice vẫn nằm trong `start_wander()`.

## U1.9f — Grazing-entry decision

`CreatureGrazingPolicy` nhận stable species ID, prey role, injected roll và protected guard. Rule giữ nguyên: chỉ prey với finite roll trong `[0,1]` và roll strict `<0.22` được accept; đúng `0.22` trả `NO_CHANGE`.

Accepted result phát `creature.transition.ecology_grazing_entry`. Transition chỉ nhận từ IDLE và dùng duration đã inject trong range legacy 2.5–4.0 giây. Actor chỉ render text sau accepted apply.

RNG ordering được giữ tại `start_wander()`:

1. Sleep roll/optional duration giữ nguyên.
2. Drink roll/optional duration giữ nguyên.
3. Chỉ prey mới tăng `grazing_roll_count` và gọi grazing roll.
4. Chỉ accepted grazing mới tăng `grazing_duration_roll_count` và gọi duration roll.
5. Nếu không grazing, wander duration rồi angle roll giữ nguyên thứ tự.

Hai counter là transient regression telemetry, không thuộc save. Sleep/drink decisions, predator panic callback và hunt lifecycle vẫn legacy.

## U1.9g — Hunt lifecycle closure

`HUNTING_PREY` nay thoát bằng hai stable event: `creature.transition.ecology_hunt_aborted` khi prey không còn hợp lệ hoặc timer hết, và `creature.transition.ecology_hunt_contact` khi khoảng cách strict `<42px`. Hai event chỉ nhận source HUNTING_PREY; lifecycle guard và stale-result guard dùng chung transition owner.

Abort chuyển về IDLE trong 2 giây. Contact giữ melee damage `int(attack_power * 0.7)`, chuyển về IDLE với recovery 3 giây và chỉ phát feedback sau accepted apply. `prey_target` là ecology reference riêng, chỉ được xóa sau accepted transition; regular combat `target` không bị thay đổi.

Movement speed ×1.05, contact boundary, damage multiplier, feedback và không-thứ-tự RNG được giữ nguyên. Regression khóa invalid prey, timeout result, contact damage/recovery, protected request và repeated/stale apply. `panic_from_predator()`, sleep/drink selection và remaining typed species catalog vẫn là writer legacy cho package sau.

## U1.9h — Predator-threat panic callback

`panic_from_predator()` nay resolve stable event `creature.transition.ecology_predator_threat`. Event yêu cầu predator target hợp lệ, từ chối source FLEE/CAPTURING và dùng lifecycle protection chung; accepted result vào FLEE 4 giây với `TargetAction.SET`.

Actor chỉ phát floating text và shake audio sau accepted apply. Target, duration và guard cũ được giữ nguyên; invalid predator fail closed. Regression khóa accepted callback từ prey selection, CAPTURING/FLEE/invalid-target guard và repeated/stale result không mutate. Sleep/drink selection cùng remaining typed species catalog vẫn legacy.

## U1.9i — Sleep-entry decision

`CreatureSleepPolicy` nhận stable species ID, night-raider/enraged flags, injected roll và protected guard. Peaceful creature chỉ sleep khi finite roll trong `[0,1]` strict `<0.18`; đúng `0.18`, night-raider và enraged trả `NO_CHANGE`. Accepted result phát `creature.transition.ecology_sleep_entry`.

Actor chỉ gọi sleep roll khi peaceful, chỉ gọi duration roll sau accepted decision và apply duration trong legacy range 6–11 giây. Transition chỉ nhận IDLE → SLEEP; stale/protected result không mutate. Transient `sleep_roll_count`/`sleep_duration_roll_count` khóa RNG short-circuit, không thuộc save. Natural precedence vẫn sleep → drink → grazing → wander; drinking và remaining typed species catalog còn legacy.
