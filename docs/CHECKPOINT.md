# Checkpoint triển khai Paloria 3.0

## U1.12v — rock depletion persistence

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Bốn rock tĩnh giữ health và respawn time qua cùng typed world-resource contract.
- Stable subtype quyết định max health 80; restore không gọi hit/drop/VFX hay serialize random texture.
- Invalid/coherence failure xảy ra trước runtime mutation; chunk streaming ngoài scope.

### Kết quả đã triển khai

- Admit `resource.rock` và bốn ID `resource.rock_1`…`resource.rock_4`.
- State dùng max health theo subtype: tree 60, rock 80; max không đi qua DTO.
- Rock chuyển từ coroutine sang cùng deterministic respawn countdown 18 giây.
- Texture rock ngẫu nhiên giữ presentation-only và không ảnh hưởng persistence identity.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Editor-load và focused save regression xanh: rock partial health 53, depleted timer 7.25, health 81 bị reject trước mutation và không tạo drop.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save shape/version không đổi; tree record cũ giữ nguyên semantics.
- Asset/provenance: none.
- Static tree/rock depletion đã phủ; world clock owner, spawn identity và chunk persistence chưa phủ.
- Rollback: revert rock IDs/subtype max-health dispatch/countdown, regression và docs U1.12v.

### Gói tiếp theo

U1.12w nối world clock owner theo `NEXT_UPDATE_PROMPT.md`.
