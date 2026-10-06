# Checkpoint triển khai Paloria 3.0

## U1.9q — Slime hop typed skill

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Dùng `skill.slime.hop` làm authority cho cooldown, movement và tween timing.
- Giữ velocity 260, height 12px và squash/stretch hiện hữu.
- Không migrate Beast charge, Dragon melee, drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm typed subtype `HopSkillDefinition` với validation movement/timing.
- Thêm `skill.slime.hop`, reference từ `creature.slime` và adapter resolution.
- Actor projection giữ nguyên scale keyframes và chỉ đọc typed tuning.

### Validation hiện tại

- Baseline full gate xanh.
- Headless import/load đăng ký global class mới.
- Focused content/actor regression xanh với 21 definitions và hop parity.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none.
- Asset/provenance: không thêm/sửa asset.
- Beast charge, Dragon/generic melee và non-Flam drop execution vẫn legacy.
- Rollback: revert U1.9q; không cần migration.

### Gói tiếp theo

U1.9r migrate riêng Beast charge tuning/lifecycle sang typed skill contract, giữ telegraph/contact/stun compatibility. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
