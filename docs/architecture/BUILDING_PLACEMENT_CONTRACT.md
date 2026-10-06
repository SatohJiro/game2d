# U1.12e — Building placement identity contract

Chín subtype placement reachable được map từ legacy recipe ID sang stable `building.*` bởi `BuildingPlacementCatalog`. Mỗi placement do Player tạo nhận `building.instance_*`; Node name, scene path và asset path không phải identity.

`BuildingPlacementRecord` là typed DTO gồm instance ID, subtype ID và transform finite (position/rotation/non-zero scale). Player giữ `placed_buildings` làm ledger, không scan SceneTree mỗi frame. Runtime node chỉ mang metadata và group `persistent_player_buildings` để lifecycle apply có thể thay đúng tập player-created; starter building trong scene không bị xóa.

Save v1 dùng `world.entity_deltas` cho placement records. Schema reject subtype không admit, instance ID sai/duplicate và transform invalid. Apply validate + instantiate toàn bộ off-tree trước khi thay nodes; subtype mutable state như health/chest/queue/ranch/crop vẫn ngoài phạm vi và sẽ có DTO riêng sau.

Shape v1 đổi pre-release nên version vẫn 1; save thiếu contract mới fail closed. Asset/provenance: none; catalog chỉ tham chiếu scene baseline. Rollback: revert catalog/record, Player ledger/factory bridge, Save world validation/apply và regression/docs U1.12e.
