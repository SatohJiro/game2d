# Prompt cho model tiếp theo — U1.8b Creature transition owner

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.8b. Đọc `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, `docs/architecture/CREATURE_PERCEPTION_CONTRACT.md`, combat/capture contracts, `MODULES.md`, `FEATURES.md` và roadmap trước khi sửa.

## Mục tiêu

Tạo một transition boundary deterministic cho nhóm state locomotion cơ bản của WildCreature, giảm direct writer trong `_physics_process` mà không viết lại skill/attack/capture/ecosystem.

## Phạm vi bắt buộc

1. Chạy full baseline gate và audit lại mọi writer `state`, `state_timer`, `target`, `prey_target`, `velocity`. Lập ma trận owner/caller và chọn một lát cắt nhỏ để migrate.
2. Ưu tiên state thuần thời gian/target: IDLE, WANDER, SUSPICIOUS và target-lost của CHASE. Không migrate fireball/spore/melee/charge, damage, capture hoặc predator-prey trong cùng package.
3. Tạo request/result hoặc command trong `systems/creature/` với stable transition reason; không đưa Node, Callable, tween hoặc scene vào pure contract.
4. Chỉ một adapter method apply state/timer/target mutation cho các transition đã migrate. Legacy writer ngoài lát cắt phải được liệt kê và giữ behavior.
5. Bảo toàn perception U1.8a: 0,20 giây, deterministic candidate ordering, protected-state guard và metric 5 query/giây.
6. Không để async attack callback đưa defeated/capturing/stunned actor về CHASE; thêm guard tại apply boundary nếu lát cắt chạm đường này.
7. Regression: valid/invalid transition, timer expiry, missing target, protected state, stable reason, apply-once hoặc idempotence phù hợp, perception compatibility, capture rejection và main smoke.
8. Cập nhật contract/module/gameplay/roadmap/checkpoint; prompt tiếp theo là U1.9a definition-driven creature skill/drop audit nếu U1.8 gate đạt.

## Giới hạn

- Không tạo BehaviorTree/global AI singleton.
- Không migrate toàn bộ 15 state trong một commit.
- Không thay balance, sprite, animation, collision, spawn, pet roster hoặc save.
- Không gắn persistent identity vào Node/ObjectID; transient ID U1.8a chỉ dùng trong một query.
- Không tuyên bố U1.8 hoàn tất nếu state writer audit còn vi phạm acceptance đã chọn.

## Definition of Done

- Pure transition tests và focused actor adapter test xanh.
- Số direct writer trong lát cắt đã chọn giảm và có before/after count.
- Full `tools/check_project.ps1` cùng log scan sạch error/leak.
- Tài liệu ghi exact migrated writers, legacy writers, compatibility, save/asset impact, rollback và manual gaps.
- Commit branch riêng và fast-forward `main` khi gate xanh.

## Hướng sản phẩm phải bảo toàn

Kiến trúc Creature phải sẵn sàng cho chunk unload ở U2: pure state không giữ Node làm dữ liệu bền vững. Paloria Luminous Town vẫn là initiative U2–U4; Your Name chỉ là mood reference và không được dùng asset/nhạc/map có bản quyền.
