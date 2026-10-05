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
