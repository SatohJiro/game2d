# U1.12g — Building placement, chest and furnace state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

`building.chest` dùng `ChestPlacementState.inventory` với stable ID `item.wood`, `item.pal_ore`, `item.berry`. U1.12g admit thêm `building.furnace` với `FurnacePlacementState`: committed ore/wood input, iron/pal output chờ nhận và `smelt_timer` trong `[0, 5)`. Progress dương chỉ hợp lệ khi còn ít nhất một batch 2 ore + 1 wood. Record cũ thiếu state được normalize thành state rỗng theo subtype; subtype khác bắt buộc state rỗng. Localized key, Node và Callable không thuộc DTO.

Chest snapshot đọc committed store và restore qua capacity-checked shadow store. Furnace snapshot giữ input đã trừ khỏi Player, output đã sản xuất và phần timer đang chạy; restore gán state đúng một lần rồi suy ra `is_smelting` từ input. Flam boost không persist vì là ảnh hưởng môi trường được tính lại mỗi frame. Save apply instantiate và apply state cho toàn bộ node off-tree trước khi thay world, nên payload invalid không xóa building hiện tại và load lặp lại không cộng dồn item.

Audit subtype còn lại: cooking pot có recipe/timer/active; compost bin có material/output/timer; ranch có food/assignment/production timer/runtime animals; farm plot có crop/stage/growth/moisture/fertilizer; altar có boss-active; turret có cooldown; mọi building có health. Các state này, chest/furnace health và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none. Rollback U1.12g: bỏ `FurnacePlacementState` và furnace projection/apply/validation; save có furnace state sau rollback sẽ fail closed.
