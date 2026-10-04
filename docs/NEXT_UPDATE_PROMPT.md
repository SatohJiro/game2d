# Prompt triển khai package U1.7a

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, roadmap, MODULES, G05 và các contract combat/player. Chạy `tools/check_project.ps1` trước khi sửa.

U1.1–U1.6 đã VERIFIED. Chỉ thực hiện U1.7a deterministic capture resolution:

1. Audit `sphere.gd`, `creature.gd:get_catch_chance/attempt_capture/capture_*` và Player throw/roster boundary. Ghi rule order, writer, random call, duplicate guard và animation timing.
2. Tạo pure `CaptureRequest`, `CaptureResult`, `CaptureResolver`. Request dùng scalar/stable IDs: target/species ID khi có, HP/max HP, sphere modifier, status/back-strike flags và injected roll. Resolver không gọi RNG, Node, SceneTree, animation, HUD hoặc audio.
3. Result phải có status, base/final chance, roll, success, applied modifiers/tags. Validate invalid HP/max, multiplier/roll range, clamp và already-capturing/invalid-target policy rõ.
4. Migrate WildCreature để chụp pre-capture state trước khi đổi CAPTURING; sửa sleep bonus unreachable bằng request flag có regression. Resolve outcome đúng một lần trước animation; presentation đọc result và commit success/failure đúng một lần sau animation.
5. Giữ signature `attempt_capture(player_ref, catch_multiplier, throw_pos)` cho Sphere. Giữ inventory sphere selection/consume, roster trait RNG, party append, despawn và animation ở adapter legacy.
6. Không migrate PetInstance/roster, sphere inventory transaction, trait RNG, save hay UI redesign trong package này.
7. Regression: full/low/zero HP chance, clamp min/max, normal/mega/giga multiplier, sleep/back-strike riêng và kết hợp, roll 0/1/equality, invalid request, deterministic repeat, duplicate capture guard và main-scene Creature adapter.
8. Cập nhật CAPTURE contract, G05, MODULES, roadmap/checkpoint. Prompt kế tiếp U1.7b phải xử lý capture commit/roster ownership và sphere inventory transaction riêng.

Kết thúc full gate, log sạch, commit branch riêng và fast-forward `main`. Ghi save/data/asset impact, compatibility, manual animation test và rollback.
