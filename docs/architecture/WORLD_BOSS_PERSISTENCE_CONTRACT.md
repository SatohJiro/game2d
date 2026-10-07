# World boss persistence contract — U1.12aa

## Audit hiện trạng

World boss do `scripts/main.gd` tạo hiện chỉ có guard `boss_spawned`. Main không giữ tham chiếu actor, actor không có stable instance ID/group riêng và `creature.gd` không phát defeat event về world owner. `boss_spawned == true` vì thế không phân biệt boss đang sống với boss đã bị hạ. Nối HP/position vào Save v1 lúc này có thể restore trùng actor hoặc phát EXP/drop lần nữa.

## Contract thuần

`WorldBossState` định nghĩa ba lifecycle ID ổn định:

- `world_boss.lifecycle.pending`: chưa spawn, instance rỗng, HP 0 và position zero.
- `world_boss.lifecycle.active`: đúng instance `boss.world_dragon_1`, HP `1..380`, position hữu hạn.
- `world_boss.lifecycle.defeated`: giữ instance cố định làm defeated ledger, HP 0 và position zero.

DTO chỉ chứa lifecycle ID, instance ID, HP và hai scalar position. Không chứa Node, scene path, banner, target, reward/drop state hoặc RNG.

## Boundary chưa được phép nối

State này chưa thuộc Save v1 và chưa được apply vào Main. Package sau chỉ được nối khi world owner giữ đúng một actor reference/group, Creature phát defeat signal trước khi free, restore path suppress presentation/reward, và defeated lifecycle ngăn respawn/reward lặp. Rollback hiện tại là xóa state/validator/docs; không có migration hay save breaking change.
