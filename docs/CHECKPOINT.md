# Checkpoint triển khai Paloria 3.0

## U1.12ae — night-raid actor audit và typed contract

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Audit identity/lifecycle của ba night-raid actor trước Save admission.
- Contract phải phân biệt pending/active/cleared theo cycle và giữ resolved actor state.
- Không serialize Node, target, scene path hoặc species/angle/radius RNG; chưa spawn khi load.

### Kết quả đã triển khai

- Thêm `NightRaidState` với `raid.lifecycle.pending|active|cleared`, encounter `raid.night_current` và cycle index.
- Thêm ba slot `raid.night_actor_1..3` chứa resolved species, level 2–5, derived elite HP và finite position.
- Active giới hạn 1–3 actor unique; pending/cleared dùng canonical empty roster và guard/cycle coherence.
- Audit xác nhận Main chưa giữ actor reference/ID và chưa aggregate defeat/capture removal; Save v1 không đổi.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused editor-load/night-raid regression xanh: JSON round-trip, unique slot, spawn-species allowlist, HP maximum và cycle/guard coherence.
- Full `tools/check_project.ps1` xanh: 43 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save/world/raid validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; raid state chưa được nối Save v1.
- Asset/provenance: none.
- Raid actor ownership/removal, restore/reward suppression và chunk persistence chưa phủ.
- Rollback: xóa night-raid state/validator/gate và docs U1.12ae.

### Gói tiếp theo

U1.12af thiết lập raid actor ownership/removal theo `NEXT_UPDATE_PROMPT.md`.
