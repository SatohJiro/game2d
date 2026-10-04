# Prompt cho model tiếp theo — U1.8c Creature lifecycle closure

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.8c. Đọc `AGENTS.md`, `CHECKPOINT.md`, `CREATURE_PERCEPTION_CONTRACT.md`, `CREATURE_TRANSITION_CONTRACT.md`, combat/capture contracts và roadmap trước khi sửa.

## Mục tiêu

Đóng ownership cho basic lifecycle transitions để có thể kết thúc U1.8, đồng thời ghi rõ combat/ecology writer nào thuộc U1.9. Không triển khai skill/drop definitions trong package này.

## Phạm vi bắt buộc

1. Chạy baseline gate và audit writer còn lại theo nhóm: timed natural state, perception entry, damage reaction, capture restore, pack/ecology, charge/skill.
2. Migrate một lát cắt đủ để basic lifecycle có apply owner:
   - `trigger_suspicion` và `trigger_alert` state/target/timer commit;
   - timed exit của SLEEP, DRINKING, GRAZING, ALERT và FLEE nếu không phụ thuộc skill;
   - capture rejection CHASE/IDLE restore nếu có thể dùng cùng lifecycle result.
3. Presentation text/audio/tween chỉ chạy sau accepted apply; rejected/stale transition không phát side effect.
4. Không migrate charge, species attack, prey kill/drop hoặc damage calculation. Ghi owner U1.9 cho writer còn lại.
5. Giữ U1.8a cadence 5 Hz và U1.8b stable event/result/apply guards.
6. Regression: perception alert/suspicion commit, natural timeout, FLEE target lost/timeout, capture rejection compatibility, stale/protected result, no duplicate presentation hook và main smoke.
7. Đếm before/after writer trong lát cắt. Chỉ đánh dấu U1.8 VERIFIED nếu mọi basic lifecycle writer đã qua boundary hoặc được phân loại rõ sang U1.9.
8. Cập nhật docs/checkpoint. Nếu gate đạt, prompt tiếp theo là U1.9a audit CreatureDefinition/skill/drop.

## Giới hạn

- Không viết BehaviorTree hoặc global AI singleton.
- Không thay balance, scene hierarchy, animation, asset, collision, spawn hay save.
- Không đưa Node/ObjectID vào persistent state.
- Không gom toàn bộ attack/ecology vào package này.

## Definition of Done

- Pure lifecycle transition và actor adapter regression xanh.
- Basic-state writer count giảm theo số đo; writer hoãn có owner/package cụ thể.
- Full `tools/check_project.ps1`, log scan và `git diff --check` sạch.
- Save/data compatibility, asset impact, rollback và manual gaps được ghi.
- Commit branch riêng, fast-forward `main` khi gate xanh.

## Hướng sản phẩm phải bảo toàn

Kiến trúc phải hỗ trợ chunk unload/persistence U2. Paloria Luminous Town vẫn là initiative U2–U4; Your Name chỉ là mood reference, không dùng map/sprite/nhạc có bản quyền.
