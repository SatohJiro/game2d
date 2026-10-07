# U1.12l — Building placement and admitted subtype state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

Các subtype chest/processing/ranch dùng typed state riêng. U1.12k admit `building.farm_plot` với `FarmPlotPlacementState`: stable crop ID, stable `farm.stage.*`, growth, moisture, watered và fertilized state. `crop.golden_wheat` và `crop.pal_herb` được thêm làm typed `CropDefinition` bên cạnh `crop.berry`. Record cũ thiếu state được normalize thành plot EMPTY.

Farm validation khóa stage/progress: EMPTY không crop và timer 0; SEEDED `<4,5`; GROWING từ `4,5` đến `<10`; READY `>=10`. Moisture nằm 0–100 và `is_watered` phải đúng với moisture dương. Apply map stable IDs về enum compatibility nhưng không chạy growth tick hoặc harvest, vì vậy không reset progress hay sinh reward.

U1.12l admit `building.altar` với `AltarPlacementState`: lifecycle `altar.lifecycle.idle|active`, stable `boss.instance_*` và HP 1–280 khi active. Restore active tạo đúng một boss mà không thu offering hoặc phát summon/completion banner; boss Node cũ được suppress lifecycle rồi thay. Boss Node không serialize.

Audit subtype còn lại: turret có cooldown; mọi building có health. Resource-node tree/rock depletion và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none. Rollback U1.12l: bỏ altar state/lifecycle bridge và boss replacement; save có altar state sau rollback sẽ fail closed.
