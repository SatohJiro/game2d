# Checkpoint triển khai Paloria 3.0

## U1.9p — Mushroom spore typed skill

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Dùng `skill.mushroom.spore` làm authority cho projectile tuning.
- Giữ kiting/escape, timing, damage, visual và lifecycle hiện hữu.
- Không migrate Slime hop, Beast charge, Dragon melee, drop execution, asset hoặc save.

### Kết quả đã triển khai

- Thêm typed spore: cooldown 2s, recovery 0,25s, damage ×1, travel 200px/0,5s, radius 45px.
- Mushroom reference stable skill; adapter resolve theo stable species ID.
- Actor dùng typed values nhưng giữ texture, màu, scale, text và target guard.

### Validation hiện tại

- Baseline full gate xanh.
- Focused content/actor regression xanh với 20 definitions và runtime parity.
- Full final gate `tools/check_project.ps1` xanh: documentation, asset integrity, content/domain validators, editor load và main-scene smoke đều đạt; log sạch lỗi nghiêm trọng.

### Compatibility, asset và giới hạn

- Save/data breaking change: none.
- Asset/provenance: không thêm/sửa asset; leaf texture giữ trạng thái baseline.
- Slime hop, Beast charge, Dragon melee và non-Flam drop execution vẫn legacy.
- Rollback: revert U1.9p; không cần migration.

### Gói tiếp theo

U1.9q migrate riêng Slime hop tuning sang typed skill contract, giữ movement/tween/contact compatibility. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
