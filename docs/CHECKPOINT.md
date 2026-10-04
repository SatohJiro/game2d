# Checkpoint triển khai Paloria 3.0

## U0.2 — asset inventory và documentation baseline

Trạng thái: `VERIFIED` ngày 2026-10-04.

### Mục tiêu và invariant

- Mọi asset nguồn hiện hữu có path, byte size và SHA-256 tái sinh được.
- Asset chưa rõ nguồn phải hiện rõ là `QUARANTINE/UNKNOWN`.
- Không di chuyển, xóa, tải mới hoặc đổi license asset; game baseline vẫn chạy.
- Mọi module, feature và phase có tài liệu nguồn sự thật để model khác tiếp tục đồng nhất.

### Thay đổi

- `tools/generate_asset_inventory.ps1`: quét source asset, reference, hash và duplicate; merge provenance đã duyệt từ override.
- `tools/check_asset_inventory.ps1`: fail khi file/size/hash/manifest lệch.
- `tools/check_documentation.ps1`: kiểm tra tài liệu bắt buộc và relative Markdown links.
- `tools/check_project.ps1`: chạy documentation/asset integrity trước editor-load và main-scene smoke.
- `docs/assets/asset_manifest.csv|json`: 166 asset nguồn; 69 referenced, 97 unreferenced, gồm 3 PNG thử nghiệm ở root.
- `docs/assets/provenance_overrides.csv`: nguồn curated không bị generator ghi đè.
- `docs/assets/INVENTORY.md`: 3 nhóm duplicate hash, tổng 18 file.
- `docs/.gdignore`: ngăn Godot import nhầm tài liệu CSV/JSON.
- `docs/INDEX.md`: chỉ mục và nguồn sự thật.
- `docs/architecture/MODULES.md`: 19 module, contract mục tiêu, ownership và adapter migration.
- `docs/gameplay/FEATURES.md`: 16 nhóm tính năng, luật/invariant/acceptance criteria.
- `docs/roadmap/IMPLEMENTATION_PHASES.md`: package U0–U6 và gate.
- `docs/process/*`: Definition of Done, ma trận cập nhật và template bàn giao.
- `docs/decisions/ADR-0001-incremental-modularization.md`: quyết định refactor theo vertical slice.

### Validation

- Lệnh: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1`.
- Asset integrity: 166/166 path, size và SHA-256 hợp lệ; 0 verified, 166 quarantine/unknown.
- Godot 4.7.2 editor-load: exit 0, log sạch.
- Main-scene smoke 120 frame: exit 0, không parse/script/resource error hoặc leak.
- Log cục bộ: `build/checks/headless-editor.log`, `build/checks/headless-smoke.log`.

### Compatibility và rủi ro

- Save/data breaking change: none. Gameplay/runtime asset path không đổi.
- Project vẫn chưa là Git repository, nên chưa có restore point/version history.
- 69 asset runtime vẫn chưa đủ điều kiện phát hành vì provenance chưa xác minh; 97 asset chưa dùng cũng đang quarantine.
- `game-dev` CLI vẫn thiếu; chưa download/admit package mới.

### Gói tiếp theo

U0.3: tạo Git repository và baseline snapshot có thể phục hồi trước refactor. Nếu Git snapshot chưa được thực hiện, chỉ được làm U0.4 documentation/provenance triage; không di chuyển asset hoặc bắt đầu migration U1.

## Lịch sử

- U0.1: sửa `is_sprinting`, audio lifecycle và tạo Godot headless editor/smoke gate; `VERIFIED` ngày 2026-10-04.
