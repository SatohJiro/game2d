# U1.12h — Building placement and admitted processing state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

`building.chest` dùng `ChestPlacementState`; `building.furnace` dùng `FurnacePlacementState`. U1.12h admit `building.cooking_pot` với `CookingPotPlacementState`: stable `recipe.cooking.*` và thời gian còn lại. `CookingRecipeCatalog` map năm legacy recipe ID sang stable identity và duration hiện hữu; runtime recipe Dictionary, localized name, icon và cost không được serialize. Record cũ thiếu state được normalize thành state rỗng theo subtype; subtype khác bắt buộc state rỗng.

Chest restore qua capacity-checked shadow store. Furnace snapshot giữ input/output/progress đã commit. Cooking pot snapshot giữ recipe có nguyên liệu đã trừ cùng timer; apply resolve lại runtime recipe từ catalog để giữ đúng future output mà không trừ nguyên liệu lần hai. `is_cooking` được suy ra từ recipe state; player-in-range, visuals và UI không persist. Save apply instantiate và apply toàn bộ state off-tree trước khi thay world.

Audit subtype còn lại: compost bin có material/output/timer; ranch có food/assignment/production timer/runtime animals; farm plot có crop/stage/growth/moisture/fertilizer; altar có boss-active; turret có cooldown; mọi building có health. Các state này và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none. Rollback U1.12h: bỏ cooking catalog/state và cooking projection/apply/validation; save có cooking state sau rollback sẽ fail closed.
