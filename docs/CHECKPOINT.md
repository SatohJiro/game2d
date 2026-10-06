# Checkpoint triển khai Paloria 3.0

## U1.12b — runtime inventory identity closure

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Mọi localized inventory key reachable hiện tại phải map hai chiều sang stable `item.*` và có typed `ItemDefinition`.
- Snapshot Player sau output core/crafting/farming/ranch/cooking không được fail `UNMAPPED_ITEM`.
- Giữ nguyên economy, Save v1 shape và legacy dictionary duy nhất; unknown key vẫn fail closed.

### Kết quả đã triển khai

- Thêm `RuntimeInventoryManifest` bao phủ 25 key theo năm nhóm runtime.
- Admit 14 definition/mapping còn thiếu cho fertilizer, elixir, crop/ranch material và cooked food; catalog tăng từ 26 lên 40 definition.
- Content validator khóa mapping hai chiều + typed definition; save validator instantiate Player và snapshot từng nhóm output.

### Validation hiện tại

- Godot editor import/load headless xanh sau thay đổi.
- `validate_content.gd` và `validate_save_schema.gd` xanh; không có parse/script/missing dependency trong hai validator trọng tâm.
- Full `tools/check_project.ps1` xanh: documentation, 166 asset integrity/action records, editor load, toàn bộ content/item/combat/player/creature/capture/pet/save validators.
- Leak-aware scan `build/checks` không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path hoặc orphan/leak warning.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; Save v1 shape không đổi và chưa có save phát hành.
- Không thêm asset ngoài. Các definition mới chỉ tham chiếu icon baseline đã có; provenance giữ `QUARANTINE/UNKNOWN`.
- Manifest ngăn drift ở contract đã khai báo nhưng chưa tự phân tích source để phát hiện producer key mới.
- Rollback: revert manifest, 14 definition, adapter mappings và regression/docs U1.12b; runtime economy không đổi.

### Gói tiếp theo

Sau khi full gate xanh, U1.12c đóng stable identity và round-trip cho pet rarity/trait/inactive stance. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
