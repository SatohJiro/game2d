# Checkpoint triển khai Paloria 3.0

## U1.9o — Dragon fireball typed skill

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Dùng stable `skill.dragon.fireball` làm authority riêng cho Dragon projectile tuning.
- Giữ melee priority/range, fireball timing/damage/travel, presentation và lifecycle guards hiện hữu.
- Không migrate Dragon melee, Slime hop, Mushroom spore, Beast charge, drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm `data/definitions/skills/dragon_fireball.tres` với cooldown 2,2s, recovery 0,3s, damage ×1, travel 240px/0,55s và radius 45px.
- `creature.dragon` reference đúng `skill.dragon.fireball`; không chia sẻ balance identity với Flam.
- `LegacySpeciesAdapter` resolve/validate primary skill theo stable species ID và expected reference.
- Dragon dispatch truyền typed definition vào projectile adapter; melee selection và presentation không đổi.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused content validator xanh với 19 definitions và Dragon cross-reference/tuning parity.
- Focused actor regression xanh cho stable skill identity, typed dispatch/cooldown và stale recovery giữ `CAPTURING`.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset integrity, content/domain validators, editor load và main-scene smoke đều đạt; log không còn script/parse/missing dependency/invalid node error.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; skill chưa persistent và runtime projectile shape không đổi.
- Asset/provenance: không thêm/sửa asset; fireball texture/audio hiện hữu vẫn giữ trạng thái baseline.
- Dragon melee cùng Slime/Mushroom/Beast skill execution và non-Flam drop execution vẫn legacy.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert U1.9o, trả Dragon `skill_ids` về empty và bỏ typed argument ở dispatch; không cần migration.

### Gói tiếp theo

U1.9p migrate riêng Mushroom spore projectile sang typed skill definition, giữ kiting/escape, timing, damage và lifecycle compatibility. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
