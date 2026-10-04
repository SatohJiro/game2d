# U1.7 — Capture resolution và ownership contract

Trạng thái: U1.7a/U1.7b/U1.7c `VERIFIED` ngày 2026-10-04
Pure domain: `systems/capture/`
Actor/presentation adapter: `scripts/creature.gd`

## Phạm vi và invariant

U1.7a tách chance calculation và outcome roll khỏi animation capture. Resolver không gọi RNG, Node, SceneTree, timer, tween, HUD hoặc audio. Adapter tạo request với một injected roll trước animation; presentation nhiều nhịp chỉ đọc result; outcome được commit tối đa một lần cho attempt đang active.

U1.7b bổ sung sphere selection/spend/flight/drop adapter theo stable item ID. U1.7c bổ sung stable species compatibility mapping và atomic roster ownership. Chi tiết request/result, rarity, token và lifecycle nằm trong `CAPTURE_OWNERSHIP_CONTRACT.md`. Ngoài phạm vi còn lại: persistent PetInstance, party capacity, typed species catalog, save và summon refactor.

Invariant:

- Cùng request tạo cùng result.
- Roll chỉ được lấy một lần trước animation và phải trong `[0,1]`.
- Chance clamp `[0.10,0.98]`; roll bằng chance thành công.
- Concurrent attempt bị chặn; invalid/defeated target không bắt đầu presentation.
- Sleep/back-strike được snapshot trước khi actor chuyển sang `CAPTURING`.
- Success/failure presentation không được tính lại chance hoặc RNG.

## Request và rule order

`CaptureRequest` gồm optional `species_id`, HP/max HP, sphere multiplier, injected roll, target/attempt/defeat guards, sleep và back-strike flags. U1.7c gắn stable species ID qua `LegacySpeciesAdapter`; năm ID hiện hữu là `creature.flam`, `creature.slime`, `creature.mushroom`, `creature.beast`, `creature.dragon`. Adapter index chỉ là compatibility input, không phải identity mới.

`CaptureResolver.resolve()` áp rule theo thứ tự:

1. Null → `INVALID_REQUEST`.
2. Target không hợp lệ → `INVALID_TARGET`.
3. Attempt đang active → `ALREADY_CAPTURING`.
4. Defeat đã commit → `ALREADY_DEFEATED`.
5. Reject max HP `<=0`, HP ngoài `[0,max]`, multiplier không dương/không finite, roll ngoài `[0,1]`/không finite.
6. `base = clamp(lerp(0.95, 0.25, hp/max), 0.15, 0.95)`.
7. `applied_multiplier = sphere_multiplier + 0.35 nếu back-strike + 0.40 nếu sleep`.
8. `final = clamp(base × applied_multiplier, 0.10, 0.98)`.
9. `succeeded = roll <= final`.

Sphere prototype hiện dùng multiplier basic 1.0, mega 2.0 và giga 4.0. Bonus cộng vào multiplier trước khi nhân base để giữ behavior thiết kế cũ. Result tags ổn định là `back_strike`, `sleep`.

## Result và status

`CaptureResult` chứa status, optional species ID, base/final chance, roll, success, applied multiplier và tags. `is_resolved()` chỉ true với `OK`.

Status: `OK`, `INVALID_REQUEST`, `INVALID_TARGET`, `ALREADY_CAPTURING`, `ALREADY_DEFEATED`.

## WildCreature adapter

- `get_catch_chance()` dùng pure base calculator cho HUD preview.
- `create_capture_request(multiplier, roll, throw_pos)` snapshot HP, sleep và facing/back-strike khi actor chưa đổi state.
- `resolve_capture_request()` thêm guard từ actor (`CAPTURING`, active attempt, committed defeat) rồi gọi resolver.
- `attempt_capture(player_ref, multiplier, throw_pos)` giữ signature cho `sphere.gd`; lấy `randf()` đúng một lần trước tween.
- `capture_attempt_active` khóa concurrent request trong toàn chuỗi await.
- `commit_capture_result()` clear attempt và gọi success/failure legacy đúng một lần sau visual.

U1.7a sửa lỗi cũ: code từng đặt state thành `CAPTURING` trước `if state == SLEEP`, khiến sleep bonus không thể chạy.

## Compatibility, save, asset và rollback

- Sphere vẫn gọi signature cũ; Player inventory/roster và creature success/failure handler không đổi.
- U1.7b stable sphere IDs: `item.pal_sphere.basic` (×1), `item.pal_sphere.mega` (×2), `item.pal_sphere.giga` (×4). Pure selector ưu tiên Giga → Mega → Basic.
- Player validate scene/parent/configuration trước atomic remove; Sphere và missed DroppedItem mang stable ID, legacy name chỉ qua adapter.
- Save/data breaking change: none. Request/result và active animation attempt là transient.
- U1.7c: accepted ownership append/reward đúng một lần; duplicate/invalid không mutation; WildCreature chỉ despawn sau accepted.
- Asset/provenance: none; capture visual vẫn dùng asset quarantine hiện tại.
- Rollback: revert commit U1.7a.

## Validation và giới hạn

`tools/validate_capture.gd` kiểm tra full/low/zero HP, clamp min/max, basic/mega/giga, sleep/back-strike/kết hợp, roll 0/1/equality, invalid/status guards, deterministic repeat, stable species mapping và ownership lifecycle accepted/rejected/duplicate. Log: `build/checks/capture-validation.log`.

Manual editor test còn cần cho timing ba lần lắc, visual restore khi fail và success despawn. Seeded RNG/replay service chưa có; deterministic boundary hiện đạt bằng injected roll.
