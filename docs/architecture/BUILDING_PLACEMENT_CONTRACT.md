# U1.12f — Building placement and chest state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

Chỉ `building.chest` được admit state trong U1.12f. `ChestPlacementState.inventory` chấp nhận stable ID `item.wood`, `item.pal_ore`, `item.berry` với count nguyên không âm. Record chest U1.12e thiếu state được normalize thành chest rỗng; subtype khác bắt buộc state rỗng. Localized key, unknown item, Node và Callable không thuộc DTO.

Chest snapshot đọc committed store. Restore tạo shadow store và chạy lại transaction capacity trước commit. Save apply instantiate và apply state cho toàn bộ node off-tree trước khi thay world, nên payload invalid/over-capacity không xóa building hiện tại và load lặp lại không cộng dồn item.

Audit subtype còn lại: furnace có input/output/timer/active/boost; cooking pot có recipe/timer/active; compost bin có material/output/timer; ranch có food/assignment/production timer/runtime animals; farm plot có crop/stage/growth/moisture/fertilizer; altar có boss-active; turret có cooldown; mọi building có health. Tất cả state này, chest health và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none. Rollback U1.12f: bỏ `ChestPlacementState`, state projection/apply và trả placement record về transform-only; save có chest state sau rollback sẽ fail closed.
