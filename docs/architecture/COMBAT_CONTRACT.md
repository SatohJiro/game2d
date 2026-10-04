# U1.5 — Combat request/result contract

## Phạm vi

U1.5 tách phép tính damage khỏi presentation và migrate hai target boundary: Player và WildCreature. Slash, pet, turret và creature attack tiếp tục gọi `take_damage`; adapter này tạo request rồi render result. Building/resource/pet health chưa migrate.

## Pure API

`DamageRequest` chứa source/target faction, current/max HP, base damage, multiplier, defense, hit/target position, knockback strength, tags, friendly-fire policy và immunity.

`CombatResolver.resolve()` không truy cập Node, SceneTree, RNG, animation hay audio. Thứ tự rule:

1. Reject null, max HP không dương, base damage không dương hoặc multiplier âm.
2. Current HP được clamp; HP 0 trả `ALREADY_DEFEATED`.
3. Immunity và same-faction damage bị chặn trừ khi request cho phép friendly fire.
4. Applied damage = `max(0, floor(base × multiplier) - max(0, defense))`.
5. Remaining HP clamp về 0; defeated đúng khi remaining bằng 0.
6. Knockback vector chỉ được tạo khi applied damage dương.

`DamageResult` status: `OK`, `INVALID_REQUEST`, `FRIENDLY_FIRE_BLOCKED`, `IMMUNE`, `ALREADY_DEFEATED`; kèm applied damage, remaining HP, defeated, knockback và tags.

## Actor adapters

- Player: armor chuyển thành multiplier 0.75; roll/invulnerability vẫn chặn trước request để giữ feedback dodge; result quyết định HP/knockback/defeat, presentation chỉ đọc result.
- WildCreature: sleep multiplier 1.75; capturing/committed defeat chặn request; legacy wild predator damage bật friendly-fire rõ ràng.
- `apply_damage_request` trên hai actor là boundary testable, mutate HP duy nhất khi result `OK`.
- Creature đặt `defeat_committed = true` trước `die()`, ngăn EXP/drop lặp trong khoảng node chờ free.
- Panic FLEE chỉ chạy khi result chưa defeated; HP 0 luôn đi death path.

## Legacy caller audit

| Caller/target | Hiện trạng sau U1.5 | Package sau |
|---|---|---|
| slash/pet/turret → creature | gọi adapter `take_damage` đã migrate | hit activation/faction IDs ở U1.8–U1.9 |
| creature projectile/melee → Player | gọi adapter đã migrate | skill definition ở U1.9 |
| creature → prey creature | adapter cho phép legacy wild damage | ecology/faction profile U1.8 |
| pet target | health logic legacy | pet state U1.10 |
| buildings/resources | health logic legacy | build/resource domain packages |
| burn tick trong creature | direct HP mutation legacy | status system U1.9 |

## Invariant và validation

- Cùng request luôn cho cùng result.
- HP và damage không âm.
- Friendly/immune/invalid/already-defeated không mutate actor.
- Defeat side effect được commit tối đa một lần trên migrated creature.
- Animation, flash, text, shake và audio không thay đổi result.

`tools/validate_combat.gd` kiểm tra pure rules và Player/Creature thật sau bootstrap main scene. `tools/check_project.ps1` chạy combat gate trước main smoke.

## Compatibility, save, asset và rollback

Signature `take_damage` cũ được giữ nên caller chưa migrate không đổi. Không có save schema impact; không thêm/sửa asset. Rollback là revert commit U1.5.

U1.6 tiếp tục tách Player input/locomotion/needs/build boundary; không mở rộng CombatResolver trong package đó trừ adapter cần thiết để giảm god script.
