# U1.8a — Creature perception contract

Trạng thái: `VERIFIED` ngày 2026-10-04

Pure domain: `systems/creature/creature_perception_*.gd`
Actor adapter: `scripts/creature.gd`

## Mục tiêu và invariant

U1.8a tách player target acquisition khỏi physics-frame loop. Node adapter thu thập candidate theo cadence cố định; pure policy quyết định `NONE`, `SUSPICIOUS` hoặc `ALERT`. Package này chưa tách toàn bộ FSM.

- Không gọi `get_nodes_in_group("player")` mỗi physics frame.
- Policy không truy cập Node, SceneTree, RNG, audio, tween hoặc HUD.
- Candidate hợp lệ được chọn theo distance tăng dần, sau đó transient candidate ID tăng dần.
- Ngưỡng aggro, suspicion và wake-from-sleep giữ phép so sánh `<` của prototype.
- Protected state và defeated không query group hoặc đổi target/state.
- Empty/invalid candidate không xóa target; target-loss timer hiện hữu vẫn là owner.
- Combat U1.5 và capture U1.7 không đổi.

## Baseline và metric

Trước U1.8a, `_physics_process()` gọi `check_aggro()` mỗi tick. Ở 60 physics FPS, mỗi creature có thể gọi player group scan 60 lần/giây khi state không bị guard.

Sau U1.8a, `CreaturePerceptionCadence` dùng interval 0,20 giây. Regression mô phỏng một giây bằng 20 tick × 0,05 giây và quan sát đúng 5 query. Mức giảm lý thuyết là `(60 - 5) / 60 = 91,67%` cho player group scan của mỗi creature đang được phép perceive.

`perception_query_count` chỉ tăng khi adapter thực sự chuẩn bị gọi group query. Cadence vẫn advance trong protected state nhưng bỏ qua query; khi state mở lại, độ trễ tối đa là 0,20 giây.

## Data contract

`CreaturePerceptionCandidate` gồm transient `candidate_id`, distance, movement speed và valid flag. ID hiện lấy từ `Object.get_instance_id()` để map result về Node trong đúng một query; ID này không được serialize hoặc dùng làm world/save identity.

`CreaturePerceptionRequest` gồm blocked/sleeping/suspicious flags, aggro/suspicion distance và copied candidate array.

`CreaturePerceptionResult` chứa decision và selected candidate ID. `has_target_decision()` chỉ true khi decision khác `NONE` và ID dương.

Policy reject request null, blocked, range không hợp lệ, candidate null/invalid, ID không dương, distance/speed âm hoặc không finite.

## Rule order

1. Request null hoặc blocked → `NONE`.
2. Range invalid → `NONE`.
3. Lọc candidate invalid, sort distance rồi candidate ID; rỗng → `NONE`.
4. Nếu sleeping: alert khi speed `>190` và distance `<90`, hoặc distance `<40`; trường hợp khác `NONE`.
5. Nếu distance `< aggro_distance` → `ALERT`.
6. Nếu distance `< suspicion_distance`, chưa suspicious và speed `>100` → `SUSPICIOUS`.
7. Còn lại → `NONE`.

Aggro distance giữ nguyên: night raider 280, elite 150, normal 115; suspicion bằng aggro + 65.

## State ownership audit

| State | Player perception | Transition/target owner hiện tại | Locomotion/side effect |
|---|---|---|---|
| IDLE/WANDER/DRINKING/GRAZING/HUNTING_PREY | Allowed theo cadence | Perception có thể gọi alert/suspicion; state handler vẫn legacy | `_physics_process` |
| SUSPICIOUS | Query nhưng không retrigger suspicion; close target có thể alert | Perception + suspicious timeout | Dừng, nhìn target |
| SLEEP | Chỉ explicit wake rule | Perception alert hoặc sleep timer | Dừng, bubble visual |
| ATTACK | Allowed để giữ behavior cũ | Async attack method vẫn ghi CHASE | Attack/tween legacy |
| CHASE/TELEGRAPH_CHARGE/CHARGING/ALERT/FLEE | Blocked trước group query | State handler/combat/ecosystem | Legacy |
| STUNNED/CAPTURING | Blocked trước group query | Status/capture contract | Không bị perception ghi đè |
| Defeated | Blocked bằng `defeat_committed` | Combat result | Despawn/reward legacy adapter |

Nhiều writer `state`, `target`, `prey_target` và `velocity` vẫn tồn tại trong `creature.gd`; U1.8b phải tách transition policy/command mà không làm lại skill/drop.

## Scan còn lại

- `update_pack_status()` và `check_predator_prey_ecosystem()` chạy cùng timer random 2,0–3,5 giây; mỗi chu kỳ hiện có hai wild-creature group scans.
- `pack_howl_alert()` scan wild creatures theo event howl.
- Các scan này không chạy mỗi physics frame và được giữ nguyên trong U1.8a. U1.8b/U1.9 phải xem xét candidate snapshot dùng chung hoặc spatial/chunk query.

## Compatibility, save, asset và rollback

- Save/data breaking change: none. Cadence, query count và candidate ObjectID đều transient.
- Scene hierarchy, collision, animation, balance và spawn path không đổi.
- Asset/provenance: none.
- Rollback: revert commit U1.8a; không cần migration.

## Validation và giới hạn

`tools/validate_creature_perception.gd` kiểm tra cadence 5 Hz, no early query, invalid delta, deterministic ordering/tie-break, threshold biên, sleep wake, invalid candidate, blocked request, no-candidate behavior và Node adapter acquisition/guard.

`tools/check_project.ps1` chạy validator này trước capture regression; capture rejection/resume tiếp tục được bảo vệ bởi `validate_capture.gd`.

Manual editor test còn cần cho cảm giác phản ứng chậm tối đa 0,20 giây, nhiều player candidate, sleep wake và raid target. Chưa có profiler frame-time/soak nhiều creature; con số 91,67% là giảm số lần gọi theo cadence có regression, không phải tuyên bố FPS.
