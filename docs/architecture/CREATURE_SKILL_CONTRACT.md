# Creature skill contract

Status: U1.9o Flam/Dragon projectile definitions, verified 2026-10-06.

## Identity and ownership

- A skill is identified only by a stable ASCII `skill.*` content ID. Method names, animation names, display text and species indexes are not identities.
- `SkillDefinition` owns deterministic tuning data. `CreatureDefinition.skill_ids` owns the ordered references available to a species.
- `creature.flam` references exactly `skill.flam.fireball` in this canary. `ContentRegistry` validates that reference in its normal two-pass load.
- `WildCreature` remains the compatibility execution adapter. It owns scene objects, tween/audio/presentation and forwards contact damage through the existing target adapter.

## Flam canary values

| Field | Value | Existing behavior preserved |
|---|---:|---|
| cooldown | 2.2 s | Time before another fireball |
| anticipation | 0.0 s | Existing immediate launch; floating telegraph text remains presentation |
| recovery | 0.3 s | Guarded `finish_legacy_attack_recovery()` delay |
| damage multiplier | 1.0 | Existing `attack_power` damage |
| travel | 240 px / 0.55 s | Existing linear projectile tween |
| hit radius | 45 px | Existing target proximity guard |

`LegacySpeciesAdapter.get_primary_skill_definition()` là projection boundary tạm thời. Nó resolve theo stable species ID, yêu cầu đúng một expected skill reference và validate typed resource trước khi trả về. Species chưa migrate trả `null` và giữ legacy execution values.

## U1.9o Dragon fireball

`creature.dragon` reference riêng `skill.dragon.fireball`; không dùng ID hoặc Resource của Flam dù parity hiện tại giống nhau. Dragon giữ cooldown 2,2 giây, recovery 0,3 giây, damage ×1, travel 240 px/0,55 giây và hit radius 45 px. Actor truyền typed definition vào cùng projectile adapter; melee priority trong khoảng 48 px và fireball range 180 px không đổi.

Regression khóa stable ID riêng, toàn bộ tuning, dispatch sang `ATTACK`, typed cooldown và stale recovery không được ghi đè `CAPTURING`.

## Validation and lifecycle invariants

- Projectile definitions require finite positive cooldown, damage multiplier, distance, travel time and hit radius. Anticipation/recovery must be finite and non-negative.
- Missing skill references fail registry validation.
- Animation, tween completion and floating text never select a skill or decide its tuning.
- The projectile callback still checks target validity and `take_damage`; recovery still refuses to overwrite defeat, capture, stun or a state newer than `ATTACK`.

## Writer audit and deferred ownership

| Writer | Current owner | Disposition |
|---|---|---|
| Flam fireball dispatch and values | typed reference + actor adapter | U1.9b canary |
| Slime hop | species-index branch | deferred; needs movement/contact skill contract |
| Mushroom spore | species-index branch | deferred; next skill catalog expansion, not this canary |
| Beast charge telegraph/charge | FSM species branch | deferred; needs transition/contact ownership together |
| Dragon fireball values | typed Dragon reference + actor adapter | U1.9o; melee selection vẫn legacy |
| Dragon melee selection/values | default species branch | deferred; cần melee contract riêng |
| Prey melee and generic melee | actor methods | deferred; ecology/faction target policy must be separated first |

## Compatibility, save and rollback

- No save schema, party snapshot, collision, spawn, capture, drop or asset changed.
- Rollback is removal of the U1.9b definition/reference and restoration of the six fireball constants in the actor method; no data migration is required.
