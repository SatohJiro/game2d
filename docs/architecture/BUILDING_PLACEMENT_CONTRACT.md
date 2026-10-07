# U1.12k — Building placement and admitted subtype state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

Các subtype chest/processing/ranch dùng typed state riêng. U1.12k admit `building.farm_plot` với `FarmPlotPlacementState`: stable crop ID, stable `farm.stage.*`, growth, moisture, watered và fertilized state. `crop.golden_wheat` và `crop.pal_herb` được thêm làm typed `CropDefinition` bên cạnh `crop.berry`. Record cũ thiếu state được normalize thành plot EMPTY.

Farm validation khóa stage/progress: EMPTY không crop và timer 0; SEEDED `<4,5`; GROWING từ `4,5` đến `<10`; READY `>=10`. Moisture nằm 0–100 và `is_watered` phải đúng với moisture dương. Apply map stable IDs về enum compatibility nhưng không chạy growth tick hoặc harvest, vì vậy không reset progress hay sinh reward.

Audit subtype còn lại: altar có boss-active; turret có cooldown; mọi building có health. Resource-node tree/rock depletion và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none; crop definitions tái sử dụng item definitions/assets baseline. Rollback U1.12k: bỏ hai crop definitions, farm catalog/state và projection/apply/validation; save có farm state sau rollback sẽ fail closed.
