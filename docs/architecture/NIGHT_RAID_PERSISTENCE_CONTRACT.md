# Night raid persistence contract — U1.12ae

## Audit hiện trạng

`trigger_night_raid()` roll species/angle/radius/level rồi spawn ba Creature nhưng Main không giữ encounter state, actor reference hay stable instance ID. Defeat/capture chỉ xử lý reward/despawn; không báo remaining roster về raid owner. `raid_triggered_this_cycle` chỉ ngăn trigger lặp, không phân biệt raid active với cleared. Vì vậy restore actor lúc này có thể duplicate encounter hoặc reward.

## Contract thuần

`NightRaidState` dùng lifecycle `raid.lifecycle.pending|active|cleared`, encounter ID `raid.night_current` và `cycle_index = floor(clock_seconds / 180)`. Active chứa tối đa ba `NightRaidActorState`, mỗi actor có slot ID `raid.night_actor_1..3`, resolved species ID trong bốn species raid hiện hữu, level 2–5, HP trong derived elite maximum và finite position. Species ID là kết quả đã resolve; RNG roll/seed không serialize.

Pending coherent với `raid_triggered_this_cycle=false`. Active/cleared coherent với guard true và đúng cycle index. Target Player, Node, scene path, AI state, drop/reward, angle/radius roll và signal connection không thuộc DTO.

## Admission gate

State chưa thuộc Save v1 và Main chưa apply nó. Trước admission, Main phải sở hữu ba slot actor, gắn encounter metadata/group, nhận defeat/capture removal đúng một lần và chuyển ACTIVE→CLEARED khi roster rỗng. Restore phải suppress telegraph/reward và không reroll species/position. Save/data breaking change hiện tại: none.
