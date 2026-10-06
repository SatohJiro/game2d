# Checkpoint triển khai Paloria 3.0

## U1.12e — building instance identity và placement delta

Trạng thái: `VERIFIED` ngày 2026-10-07.

### Mục tiêu và invariant

- Player-created building dùng stable instance/subtype identity; không dùng Node name hoặc scene path.
- Save/load giữ transform và chỉ thay player-created nodes; starter scene nodes không bị xóa.
- Không persist health, chest, processing, ranch hoặc crop state; không đổi cost/placement gameplay.

### Kết quả đã triển khai

- Thêm `BuildingPlacementCatalog` cho chín subtype reachable và typed `BuildingPlacementRecord`.
- Player placement tạo `building.instance_*`, metadata/group và ledger `placed_buildings`.
- Save v1 validate unique identity + finite transform; apply stage toàn bộ nodes trước khi replace group.
- Regression snapshot/apply chứng minh stable subtype/transform và scene-path identity rejection.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Godot editor import/load và `validate_save_schema.gd` focused regression xanh.
- Full `tools/check_project.ps1` xanh: 41 Markdown files, asset gates, editor load và toàn bộ gameplay/save validators.
- Leak-aware scan `build/checks` không có script/parse/missing dependency/invalid node path hoặc orphan/leak warning.

### Compatibility, asset và giới hạn

- Save v1 shape của `world.entity_deltas` được khóa cho placement record, version giữ 1 vì pre-release.
- Asset/provenance: none; chỉ tham chiếu scene baseline hiện hữu.
- Subtype mutable state và static starter placement chưa thuộc ledger.
- Rollback: revert building catalog/record, Player ledger/factory bridge, Save adapter/schema và docs U1.12e.

### Gói tiếp theo

Sau full gate xanh, U1.12f audit subtype state và chọn một slice chest hoặc processing. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
