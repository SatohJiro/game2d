# Checkpoint triển khai Paloria 3.0

## U0.4 — asset quarantine/replacement triage

Trạng thái: `VERIFIED` ngày 2026-10-04 trên branch `work/u0.4-asset-triage`.

### Mục tiêu và invariant

- Mỗi asset manifest có action, priority, owner và rationale để model sau xử lý đồng nhất.
- 69 runtime asset không rõ provenance phải giữ P0 cho tới khi verified hoặc được thay thế.
- Không xóa, di chuyển, đổi reference, tải mới hoặc đổi license asset trong package này.
- Gameplay, scene và save/data contract không đổi.

### Thay đổi

- `tools/generate_asset_triage.ps1`: merge manifest với curated override và sinh action/report.
- `tools/check_asset_actions.ps1`: fail khi thiếu asset/action, field không hợp lệ hoặc runtime asset rời P0 khi chưa verified.
- `tools/check_project.ps1`: gate mới chạy documentation → hash inventory → asset actions → Godot editor/smoke.
- `docs/assets/asset_actions.csv`: mapping generated cho 166 asset.
- `docs/assets/asset_action_overrides.csv`: nguồn curated bền vững qua lần regenerate.
- `docs/assets/REPLACEMENT_PLAN.md`: owner, ưu tiên, deliverable và migration order.

### Kết quả triage

| Action | Priority | Files | Ý nghĩa |
|---|---|---:|---|
| `VERIFY_OR_REPLACE` | P0 | 69 | Runtime dependency; xác minh nguồn/license hoặc thay trước phát hành |
| `HOLD_FOR_REVIEW` | P2 | 27 | Content chưa dùng, cần quyết định trước khi giữ/xóa |
| `DEDUP_AFTER_REFERENCE_AUDIT` | P2 | 1 | Duplicate chưa dùng; chọn canonical ở package riêng |
| `REMOVE_AFTER_REFERENCE_AUDIT` | P3 | 69 | Scratch/preview/intermediate; chỉ xóa sau reference/visual audit |

P0 owner: gameplay-art 31, environment-art 13, audio 9, VFX 9, character-art 7.

### Validation

- Lệnh: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1`.
- Documentation: 19 required files, 17 Markdown files scanned.
- Asset integrity: 166/166 path, size và SHA-256 hợp lệ.
- Asset action: 166/166 classified; 69 runtime P0.
- Godot 4.7.2 editor-load và main-scene smoke: exit 0, log sạch.

### Compatibility và rủi ro

- Save/data/gameplay breaking change: none.
- Triage theo tên/reference/hash, chưa phải human visual review hoặc license verification.
- 166 asset vẫn `QUARANTINE/UNKNOWN`; chưa đủ điều kiện phân phối.
- `game-dev` CLI vẫn thiếu; chưa download/admit asset mới.
- Package U0.4 được tích hợp vào `main` bằng fast-forward; branch package vẫn giữ để truy vết.

### Gói tiếp theo

Tạo branch U1.1 từ `main` đã có U0.4. U1.1 tạo stable content ID contract, definition base/registry và validator; migrate tối đa một slice nhỏ, chưa refactor toàn bộ player/creature.

## Lịch sử

- U0.3: Git `main`, baseline commits/tag và restore worktree test; `VERIFIED` ngày 2026-10-04.
- U0.2: manifest 166 asset, documentation/module/gameplay catalog và validation gates; `VERIFIED` ngày 2026-10-04.
- U0.1: sửa `is_sprinting`, audio lifecycle và Godot headless gate; `VERIFIED` ngày 2026-10-04.
