# Checkpoint triển khai Paloria 3.0

## U1.3 — Recipe, Building và Crop definitions

Trạng thái: `VERIFIED` ngày 2026-10-04; package được tích hợp từ branch `work/u1.3-domain-definitions` vào `main` bằng fast-forward.

### Mục tiêu và invariant

- Tạo typed catalog canary cho recipe sphere, workbench và berry crop từ prototype hiện có.
- Mọi identity mới dùng stable ID; tên tiếng Việt, scene path và icon path không làm identity.
- Validate field/domain/range trước khi register; validate cross-reference sau khi toàn catalog đã load.
- Giữ dictionary recipe/inventory, building script và CropType enum làm runtime authority trong U1.3.
- Không tạo runtime store thứ hai, không đổi gameplay/balance/save và không thêm asset.

### Schema và catalog

- `ItemAmount`: `item_id` domain item và quantity dương.
- `RecipeDefinition`: inputs/output/station/time/unlock; reject null, duplicate input, sai domain và range.
- `BuildingDefinition`: scene/health/build cost/supported recipes/tags.
- `CropDefinition`: seed/harvest item, growth time và yield range.
- Item support: `item.pal_ore`, `item.pal_sphere.basic`, `item.berry_seed`, `item.berry`.
- Domain canary: `recipe.pal_sphere.basic`, `building.workbench`, `crop.berry`.
- Catalog hiện có đúng 8 definition tính cả `item.wood`.

Chi tiết field, prototype mapping, ownership và compatibility nằm trong `docs/architecture/DOMAIN_DEFINITIONS.md`.

### Registry và validation

- `ContentDefinition.get_referenced_content_ids()` là hook reference mặc định.
- `ContentRegistry.load_directory()` register file theo path sort, sau đó validate reference theo stable ID sort.
- Missing input/output/station/cost/recipe/seed/harvest target làm content gate thất bại.
- Recipe ↔ building reference hai chiều hợp lệ vì pass reference chạy sau khi register toàn catalog.
- `tools/validate_content.gd` có regression cho wrong domain, required field, non-positive value, inverted yield, duplicate ID, missing reference và toàn bộ canary project.

### File chính

- `data/definitions/item_amount.gd`
- `data/definitions/recipe_definition.gd`
- `data/definitions/building_definition.gd`
- `data/definitions/crop_definition.gd`
- `data/definitions/items/{pal_ore,pal_sphere_basic,berry_seed,berry}.tres`
- `data/definitions/recipes/pal_sphere_basic.tres`
- `data/definitions/buildings/workbench.tres`
- `data/definitions/crops/berry.tres`
- `data/content_registry.gd`, `tools/validate_content.gd`
- Tài liệu data/module/gameplay/roadmap và kế hoạch U1.4 đã đồng bộ.

### Validation

Lệnh:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1
```

Kết quả cuối ngày 2026-10-04:

- Documentation: 24 required files, 22 Markdown files, không broken relative link.
- Asset integrity/action: 166/166; 0 verified, 166 quarantine/unknown; 69 runtime P0.
- Godot 4.7.2 editor-load: exit 0, log sạch.
- Content validation: 8 definition, subtype rules và cross-reference pass.
- Item migration U1.2: pass.
- Main scene smoke 120 frame: exit 0, log sạch.
- Log: `build/checks/headless-editor.log`, `content-validation.log`, `item-migration-validation.log`, `headless-smoke.log`.

### Compatibility, asset và phần chưa làm

- Save/data breaking change: không; dự án chưa có save system và runtime không consume definition U1.3.
- Bốn item mới chưa được map trong `LegacyItemAdapter`; stable pickup API chỉ support wood như U1.2.
- Recipe Player, workbench health/interaction và berry crop logic vẫn hardcode. Typed resources là mirror đã validate, chưa phải runtime authority.
- Registry chưa là autoload; lifecycle/bootstrap phải được owner rõ ràng khi U1.4 cần max stack/catalog.
- Recipe cycle validation chưa triển khai; U1.3 chỉ có một recipe và reference existence.
- Không thêm hoặc sửa asset byte. Icon/scene được tham chiếu đều là file cũ và vẫn `QUARANTINE/UNKNOWN`.
- Visual/manual playtest chưa thực hiện; package không đổi runtime gameplay và được kiểm bằng editor/content/item/smoke headless.

### Rollback và package kế tiếp

Rollback là revert commit U1.3; runtime chưa đọc definitions nên không có data migration ngược.

U1.4 làm theo `docs/roadmap/U1_4_INVENTORY_PLAN.md`: pure transaction trên một backing dictionary, stable add/remove/transfer, rollback hai đầu và migration pickup/chest. Nếu capacity + chest vượt work package 0,5–2 ngày, tách U1.4a transaction/Player/drop và U1.4b chest/capacity.

## Lịch sử

- U1.2: stable `item.wood` pickup/inventory adapter; `VERIFIED` ngày 2026-10-04.
- U1.1: stable content IDs, ItemDefinition, registry và validator; `VERIFIED` ngày 2026-10-04.
- U0.1–U0.4: baseline, asset inventory, Git restore point và quarantine actions; `VERIFIED`.
