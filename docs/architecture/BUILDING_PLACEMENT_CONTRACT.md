# U1.12i — Building placement and admitted processing state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

`building.chest`, `building.furnace` và `building.cooking_pot` dùng typed state riêng. U1.12i admit `building.compost_bin` với `CompostBinPlacementState`: material đã commit, fertilizer chờ nhận và timer trong chu kỳ 8 giây. Material bắt buộc 0–10, output không âm; timer dương chỉ hợp lệ khi còn material. Record cũ thiếu state được normalize thành state rỗng theo subtype; subtype khác bắt buộc state rỗng.

Chest restore qua capacity-checked shadow store. Furnace, cooking pot và compost snapshot giữ input/output/progress đã commit; apply gán state đúng một lần nên không trừ lại input hoặc cộng lại output. Presentation, player-in-range và UI không persist. Save apply instantiate và apply toàn bộ state off-tree trước khi thay world.

Audit subtype còn lại: ranch có food/assignment/production timer/runtime animals; farm plot có crop/stage/growth/moisture/fertilizer; altar có boss-active; turret có cooldown; mọi building có health. Các state này và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none. Rollback U1.12i: bỏ compost state và projection/apply/validation; save có compost state sau rollback sẽ fail closed.
