# Night raid persistence contract — U1.12ae–ag

## Audit ban đầu

`trigger_night_raid()` roll species/angle/radius/level rồi spawn ba Creature nhưng Main không giữ encounter state, actor reference hay stable instance ID. Defeat/capture chỉ xử lý reward/despawn; không báo remaining roster về raid owner. `raid_triggered_this_cycle` chỉ ngăn trigger lặp, không phân biệt raid active với cleared. Vì vậy restore actor lúc này có thể duplicate encounter hoặc reward.

## Contract thuần

`NightRaidState` dùng lifecycle `raid.lifecycle.pending|active|cleared`, encounter ID `raid.night_current` và `cycle_index = floor(clock_seconds / 180)`. Active chứa tối đa ba `NightRaidActorState`, mỗi actor có slot ID `raid.night_actor_1..3`, resolved species ID trong bốn species raid hiện hữu, level 2–5, HP trong derived elite maximum và finite position. Species ID là kết quả đã resolve; RNG roll/seed không serialize.

Pending coherent với `raid_triggered_this_cycle=false`. Active/cleared coherent với guard true và đúng cycle index. Target Player, Node, scene path, AI state, drop/reward, angle/radius roll và signal connection không thuộc DTO.

## Admission gate

State chưa thuộc Save v1. Restore tương lai phải suppress telegraph/reward và không reroll species/position. Save/data breaking change hiện tại: none.

## Runtime ownership — U1.12af

Main giữ map ba stable slot sang đúng ba Creature đã spawn. Trigger resolve toàn bộ spawn roll trước khi commit, gắn encounter/instance metadata và group `persistent_night_raid_actors`, rồi publish ACTIVE ledger; guard/state/reference không pending thì fail closed trước RNG và spawn.

Defeat hoặc captured removal chỉ được aggregate khi actor reference, slot ID, encounter metadata và group đều khớp ownership. Foreign, unknown-reason và duplicate callback không đổi state. Mỗi removal tái tạo ACTIVE ledger từ roster còn lại; roster rỗng chuyển CLEARED đúng một lần. Sang đầu chu kỳ mới chỉ reset CLEARED/PENDING, không orphan một encounter ACTIVE. Reward, drop và capture resolution vẫn thuộc Creature/capture systems.

## Save v1 admission — U1.12ag

`world.night_raid_state` lưu exact typed DTO. Snapshot ACTIVE đọc HP/position hiện tại từ đúng owned actor nhưng giữ species/level/slot đã resolve; CLEARED/PENDING giữ canonical empty roster. Schema bắt buộc lifecycle, guard và `floor(clock_seconds / 180)` coherent trước apply.

Main restore ACTIVE bằng stable species ID, slot, level, HP và position đã lưu; không gọi `trigger_night_raid()`, không roll RNG và không phát banner/reward/drop. CLEARED/PENDING dọn actor raid hiện hữu và không spawn. Save v1 pre-release cũ thiếu field được suy ra bảo thủ: guard false thành PENDING, guard true thành CLEARED của cycle hiện tại; không bao giờ suy ra ACTIVE hoặc tạo actor.

Repository/migration/schema failure không chạm runtime raid owner. Node, target, signal, scene path, RNG và presentation vẫn không thuộc DTO. Save shape vẫn version 1 vì chưa có format phát hành; thay đổi shape sau phát hành phải tăng version và có migration.
