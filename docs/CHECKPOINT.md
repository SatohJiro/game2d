# Checkpoint triển khai Paloria 3.0

## U1.1 — stable content IDs và definition registry

Trạng thái: `VERIFIED` ngày 2026-10-04 trên branch `work/u1.1-content-registry`.

### Mục tiêu và invariant

- Content có identity ổn định tách khỏi localized text, asset path và scene path.
- Typed Resource tự validate; registry reject invalid type/field và duplicate ID trước runtime.
- Chỉ thêm `item.wood` làm canary; inventory, recipe, chest, drop và HUD runtime vẫn giữ legacy key `Gỗ`.
- Không đổi gameplay, save format, asset path hoặc license status.

### Code và data

- `core/content_id.gd`: grammar lowercase dotted ID; API `is_valid`, `make`, `domain_of`, `local_name_of`.
- `data/definitions/content_definition.gd`: base Resource với `content_id`, localization key và validation.
- `data/definitions/item_definition.gd`: item domain, max stack, icon và tags.
- `data/content_registry.gd`: recursive deterministic load, type/field/duplicate validation và typed queries.
- `data/definitions/items/wood.tres`: canary `item.wood`, max stack 999, icon hiện hữu.
- `tools/validate_content.gd`: contract tests cho valid/invalid IDs, duplicate rejection và project definition load.
- `tools/check_project.ps1`: thêm `content-validation.log` giữa editor-load và main-scene smoke.

### Tài liệu

- `docs/architecture/DATA_CONTRACTS.md`: grammar/domain, definition/registry API, failure policy, localization, save và legacy mapping.
- `docs/decisions/ADR-0002-stable-content-ids.md`: quyết định identity/data migration.
- Module catalog, gameplay G03, roadmap, prompt tiếp theo và agent rules đã đồng bộ.

### Validation

- Lệnh: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1`.
- Documentation: 21 required files, 19 Markdown files scanned.
- Asset integrity/action: 166/166; 69 runtime P0.
- Content: `item.wood` load đúng subtype/icon/max stack; ID grammar tests xanh; duplicate bị reject và không overwrite.
- Godot 4.7.2 editor-load, content validation và 120-frame main smoke: exit 0, log sạch.

### Compatibility và rủi ro

- Save/data breaking change: none; chưa có save system và runtime chưa dùng stable ID.
- Mapping dự kiến: `Gỗ` → `item.wood`; adapter chưa được nối vào player/drop/chest.
- `assets/items/wood.png` vẫn `QUARANTINE/UNKNOWN`; Resource reference không xác minh license.
- Registry chưa là autoload; lifetime/bootstrap sẽ được chọn khi consumer runtime đầu tiên được migrate.
- Generic command/result/RNG chưa được tạo vì U1.1 chưa có domain consumer; tạo cùng combat/inventory package tương ứng.
- Package U1.1 được tích hợp vào `main` bằng fast-forward; branch package vẫn giữ để truy vết.

### Gói tiếp theo

Tạo branch U1.2 từ `main` đã có U1.1. U1.2 tạo item catalog tối thiểu và adapter legacy cho một luồng `wood pickup → inventory`, giữ các consumer recipe/chest/HUD khác tương thích. Viết regression cho add/read wood bằng stable ID trước khi mở rộng item khác.

## Lịch sử

- U0.4: action/priority/owner cho 166 asset; `VERIFIED` ngày 2026-10-04.
- U0.3: Git baseline/tag và restore worktree test; `VERIFIED` ngày 2026-10-04.
- U0.2: asset manifest và documentation gates; `VERIFIED` ngày 2026-10-04.
- U0.1: parse/audio lifecycle và Godot headless gate; `VERIFIED` ngày 2026-10-04.
