# World boss persistence contract — U1.12aa

## Audit hiện trạng

World boss do `scripts/main.gd` tạo hiện chỉ có guard `boss_spawned`. Main không giữ tham chiếu actor, actor không có stable instance ID/group riêng và `creature.gd` không phát defeat event về world owner. `boss_spawned == true` vì thế không phân biệt boss đang sống với boss đã bị hạ. Nối HP/position vào Save v1 lúc này có thể restore trùng actor hoặc phát EXP/drop lần nữa.

## Contract thuần

`WorldBossState` định nghĩa ba lifecycle ID ổn định:

- `world_boss.lifecycle.pending`: chưa spawn, instance rỗng, HP 0 và position zero.
- `world_boss.lifecycle.active`: đúng instance `boss.world_dragon_1`, HP `1..380`, position hữu hạn.
- `world_boss.lifecycle.defeated`: giữ instance cố định làm defeated ledger, HP 0 và position zero.

DTO chỉ chứa lifecycle ID, instance ID, HP và hai scalar position. Không chứa Node, scene path, banner, target, reward/drop state hoặc RNG.

## U1.12ab actor ownership

Main hiện giữ đúng một `world_boss_actor`, gắn group `persistent_world_bosses` và metadata `boss.world_dragon_1`. Creature phát `defeated(actor, encounter_instance_id)` trước khi tween/free; Main chỉ commit `DEFEATED` khi actor reference, group và ID cùng khớp. Callback lặp, quái thường và altar boss đều fail closed. `spawn_boss(false)` chỉ suppress banner/audio để test và chuẩn bị restore, không đổi damage/reward/drop.

## U1.12ac Save v1 admission

Save mới ghi `world.world_boss_state`; save cũ thiếu field suy ra PENDING khi guard chưa spawn và DEFEATED khi guard đã spawn. Schema khóa coherence với `WorldCycleState`. Active restore thay actor cũ bằng đúng một actor có HP/position đã lưu qua đường không banner/audio/reward; pending/defeated không spawn. Corrupt/invalid snapshot dừng trước Main apply. Node, target, signal connection, scene path, EXP/drop và RNG không serialize.
