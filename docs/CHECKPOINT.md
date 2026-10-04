# Checkpoint triển khai Paloria 3.0

## U1.8b — Creature transition owner slice

Trạng thái: `VERIFIED` ngày 2026-10-04; package branch `work/u1.8b-creature-transitions`.

### Mục tiêu và invariant

- Pure transition result quyết định state/timer/target action cho lát cắt đã chọn.
- Một apply boundary mutate state/timer/target và reject stale/protected result.
- Giữ nguyên threshold/timer/gameplay của IDLE/WANDER/SUSPICIOUS/CHASE-loss.
- Async attack callback không được ghi đè defeated/capture/stun.

### Kết quả đã triển khai

- Thêm `CreatureTransitionRequest`, `CreatureTransitionResult`, `CreatureTransitionPolicy`.
- Stable state/event/reason IDs; không dùng Node hoặc localized display text trong pure contract.
- Migrate 5 direct-assignment block của lát cắt về `apply_creature_transition()`.
- Accepted apply có transient counter; apply lại result cũ fail do from-state mismatch.
- Tách alert presentation khỏi suspicion state commit.
- Gom ba async attack recovery về helper có ATTACK/lifecycle guard.

Contract và writer audit: `architecture/CREATURE_TRANSITION_CONTRACT.md`.

### Validation hiện tại

- Focused Creature validator đạt perception U1.8a, pure transition rules, actor apply-once và attack recovery guard.
- Full `tools/check_project.ps1` đạt: 26 required file, 32 Markdown file, 166 asset inventory/action; mọi Godot regression và main smoke xanh.
- Log scan không có script/parse/dependency/runtime error hoặc resource leak.

### Compatibility, save, asset và giới hạn

- Save/data breaking change: none; toàn bộ contract/count là transient.
- Asset/provenance: không thêm hoặc sửa asset; 166 asset giữ nguyên.
- 5 direct assignment block trong lát cắt giảm xuống 0; nhiều writer ngoài lát cắt còn legacy.
- U1.8 chưa hoàn tất: timed natural states, perception entry, damage/capture restore và ecology vẫn cần ownership rõ.
- Manual test còn cần cho alert feedback/howl, wander, leash và attack interrupted.
- Rollback: revert commit U1.8b; không cần migration.

### Gói tiếp theo

U1.8c đóng basic lifecycle transition còn lại và phân loại writer nào chuyển U1.9. Không triển khai definition-driven skill/drop trong cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.

## Hướng sản phẩm phải giữ

- Perception/transition state không được giữ Node như dữ liệu bền vững để sẵn sàng chunk unload U2.
- Paloria Luminous Town vẫn là initiative U2–U4; content phải nguyên bản và có license/provenance.
- Asset admission mới còn bị chặn vì `game-dev` CLI chưa có trong PATH.
