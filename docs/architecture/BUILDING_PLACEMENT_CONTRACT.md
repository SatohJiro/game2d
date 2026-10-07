# U1.12j — Building placement, processing and ranch state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

Các subtype chest/furnace/cooking/compost dùng typed state riêng. U1.12j admit `building.ranch` với `RanchPlacementState`: food không âm, tối đa hai assignment stable và timer `[0,10)`. Pet sở hữu dùng `pet.instance_*`; resident Slime mặc định dùng `ranch.resident_starter`, scoped trong building record. Assignment ID phải unique và species phải thuộc catalog hiện hữu. Record cũ thiếu state được normalize rồi ranch `_ready` tái lập resident mặc định.

Ranch snapshot chỉ giữ food/assignment/species/progress. `animal_nodes`, Sprite, random wander/eat/sleep state và localized pet name là presentation được dựng lại sau add-tree. Apply không chạy production hoặc cấp lại reward; Save apply instantiate và apply toàn bộ state off-tree trước khi thay world.

Audit subtype còn lại: farm plot có crop/stage/growth/moisture/fertilizer; altar có boss-active; turret có cooldown; mọi building có health. Các state này và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none. Rollback U1.12j: bỏ ranch state/identity bridge và projection/apply/validation; save có ranch state sau rollback sẽ fail closed.
