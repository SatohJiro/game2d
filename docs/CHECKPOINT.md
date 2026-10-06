# Checkpoint triển khai Paloria 3.0

## U1.9r — Beast charge typed skill

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Typed authority cho Beast charge range, timing, velocity và stun.
- Giữ FSM transition, wall/timeout, contact và feedback.
- Không migrate melee, drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm `ChargeSkillDefinition` và `skill.beast.charge`.
- Beast reference stable skill; adapter resolve/validate theo species ID.
- Actor FSM đọc range 70–220, telegraph 0,45s, cooldown 3,5s, speed 330, duration 0,95s và stun 1,4s.

### Validation hiện tại

- Baseline full gate xanh; headless import/load đăng ký subtype mới.
- Focused content/actor regression xanh với 22 definitions và charge parity.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none. Asset/provenance: none.
- Dragon/generic melee và non-Flam drop execution vẫn legacy.
- Rollback: revert U1.9r; không cần migration.

### Gói tiếp theo

U1.9s audit và migrate generic melee tuning sang typed skill boundary, giữ species dispatch/target/lifecycle compatibility. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
