# Checkpoint triển khai Paloria 3.0

## U1.5 — deterministic combat result

Trạng thái: VERIFIED ngày 2026-10-04; package sẽ được fast-forward từ work/u1.5-combat-result vào main.

### Kết quả

- Thêm pure DamageRequest, DamageResult và CombatResolver.
- Rule deterministic cho invalid request, immunity, friendly fire, multiplier, defense, HP clamp, defeat, tags và knockback.
- Player armor/HP/knockback route qua result; dodge guard giữ feedback cũ.
- WildCreature sleep multiplier/HP/knockback/death route qua result.
- Creature commit defeat trước die, ngăn EXP/drop lặp.
- Prey defeated không còn đi FLEE rồi bỏ qua death.
- Signature take_damage cũ được giữ cho slash/pet/turret/creature projectile.

### Validation

tools/check_project.ps1 đạt:

- 26 required docs, 24 Markdown.
- 166/166 asset, provenance không đổi.
- Editor-load, content, inventory, combat và 120-frame main smoke đều pass.
- Combat regression kiểm tra zero/invalid, defense clamp, friendly block, immune, deterministic repeat, lethal, knockback/tags và adapter Player/Creature.
- Log mới: build/checks/combat-validation.log.

### Compatibility và giới hạn

- Save/data breaking change: none.
- Không thêm/sửa asset.
- Status tick burn, pet/building/resource health và source hit activation còn legacy.
- Faction hiện là StringName boundary; stable actor instance ID chưa có.
- Player defeat vẫn respawn theo behavior prototype.
- Rollback bằng revert commit U1.5.

### Gói tiếp theo

U1.6 được chia nhỏ. U1.6a tách Player needs state/clock calculation khỏi player.gd thành pure state với snapshot/result, giữ UI và input adapter. Không tách locomotion, build và needs cùng một commit.

## Lịch sử

- U1.4: inventory transaction + chest capacity.
- U1.3: typed domain definitions.
- U1.2: stable wood adapter.
- U1.1: stable IDs/registry.
