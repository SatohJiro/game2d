# Checkpoint triển khai Paloria 3.0

## U1.9s — typed melee skill boundary

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Typed melee tuning với identity riêng cho Beast/Dragon.
- Giữ dispatch range, cooldown, lunge, contact, damage, tween và lifecycle.
- Không migrate drops, asset hoặc save.

### Kết quả đã triển khai

- Thêm `MeleeSkillDefinition`, `skill.beast.melee`, `skill.dragon.melee`.
- Creature references chứa primary skill và melee skill; adapter resolve từng role theo stable ID.
- Actor giữ target guard/damage/recovery, đọc typed activation 38/48px và shared observed tuning.

### Validation hiện tại

- Baseline full gate xanh; headless import/load đăng ký subtype mới.
- Focused content/actor regression xanh với 24 definitions và separate identity parity.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none. Asset/provenance: none.
- Non-Flam defeat drop execution vẫn legacy.
- Rollback: revert U1.9s; không cần migration.

### Gói tiếp theo

U1.9t migrate defeat drop execution còn lại sang deterministic typed result/atomic commit. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
