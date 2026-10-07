# U1.12p — Building placement and admitted subtype state contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` gồm instance ID, subtype ID, transform finite và `state` theo subtype. Player giữ placement ledger, không scan SceneTree mỗi frame; snapshot chỉ query group một lần khi save để chiếu transform/state live. Starter building trong scene không bị thay.

Các subtype chest/processing/ranch dùng typed state riêng. U1.12k admit `building.farm_plot` với `FarmPlotPlacementState`: stable crop ID, stable `farm.stage.*`, growth, moisture, watered và fertilized state. `crop.golden_wheat` và `crop.pal_herb` được thêm làm typed `CropDefinition` bên cạnh `crop.berry`. Record cũ thiếu state được normalize thành plot EMPTY.

Farm validation khóa stage/progress: EMPTY không crop và timer 0; SEEDED `<4,5`; GROWING từ `4,5` đến `<10`; READY `>=10`. Moisture nằm 0–100 và `is_watered` phải đúng với moisture dương. Apply map stable IDs về enum compatibility nhưng không chạy growth tick hoặc harvest, vì vậy không reset progress hay sinh reward.

U1.12l admit `building.altar` với `AltarPlacementState`: lifecycle `altar.lifecycle.idle|active`, stable `boss.instance_*` và HP 1–280 khi active. Restore active tạo đúng một boss mà không thu offering hoặc phát summon/completion banner; boss Node cũ được suppress lifecycle rồi thay. Boss Node không serialize.

U1.12m admit `building.turret` với `TurretPlacementState`. DTO chỉ chứa `cooldown_remaining` hữu hạn trong `[0, 1.25]`; damage, range và fire interval vẫn là tuning runtime. Target được tìm mới mỗi physics tick, còn target Node, Callable, projectile và tween đang bay là transient nên không serialize. Apply chỉ gán cooldown, không gọi targeting hay `fire_projectile()`.

U1.12n mở rộng `ChestPlacementState` bằng durability `health` nguyên trong `[1, 250]`, bên cạnh inventory đã admit. State cũ chỉ có inventory được normalize về 250. Staged restore giữ health qua `_ready()` bằng pending scalar rồi gán trực tiếp; không gọi `take_damage()`, destruction, reward hoặc presentation. Health 0 biểu diễn chest đã bị phá nên không phải placement live hợp lệ.

U1.12o mở rộng `FurnacePlacementState` bằng durability `health` nguyên trong `[1, 300]`. State processing năm field cũ được normalize về 300. Pending scalar giữ health qua `_ready()`; restore gán input/output/progress/health trực tiếp và không gọi `take_damage()`, smelting tick, destruction, reward hoặc presentation.

U1.12p thiết lập durability foundation còn thiếu cho `building.cooking_pot` với max health 200, ngang workbench/crafting station hiện tại, rồi mở rộng `CookingPotPlacementState` bằng health `[1, 200]`. State recipe/progress cũ mặc định 200. Restore resolve recipe trước mutation, giữ health qua `_ready()` và không gọi cooking tick, finish/reward hoặc destruction.

Audit subtype còn lại: ranch/altar/turret/workbench có health chưa persist; compost/farm plot chưa có durability runtime. Resource-node depletion và runtime Node references vẫn ngoài phạm vi.

Shape v1 đổi pre-release nên version vẫn 1. Asset/provenance: none. Rollback U1.12p: bỏ cooking-pot health/damage foundation và state field; save mới có health sau rollback sẽ fail closed.
