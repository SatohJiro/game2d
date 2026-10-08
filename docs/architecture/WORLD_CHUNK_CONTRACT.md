# U2.1 — World chunk identity contract

Trạng thái: `VERIFIED` ngày 2026-10-08.

## Phạm vi và invariant

U2.1 tạo nền identity/coordinate cho world rộng nhưng không stream Node. `BiomeDefinition` và `ChunkDefinition` là typed `ContentDefinition`; display key không làm identity. Canary hiện tại là `biome.paloria_meadow` và `chunk.paloria_origin`, trong đó chunk origin tham chiếu biome qua registry.

Mỗi chunk có kích thước canonical 1024×1024 world units. World position dùng floor division, vì vậy `(-0.001, -0.001)` thuộc `(-1, -1)`, còn `(1024, 1024)` thuộc `(1, 1)`. Runtime coordinate key mã hóa dấu theo `chunk.pN.nN`; ví dụ `(-1, 1)` là `chunk.n1.p1`. Raw minus, leading zero và negative zero bị từ chối; key luôn round-trip và hợp grammar `ContentId`.

## Ownership và adapter

- `ChunkCoordinate`: pure position/coordinate/origin/key conversion.
- `WorldChunkCatalog`: resolve context cho static-world compatibility; hiện mọi coordinate dùng canary definition/biome cho tới khi U2.2 có admission policy.
- `WorldChunkContext`: snapshot read-only gồm coordinate, runtime chunk key, definition ID và biome ID; không giữ Node/Callable.
- `Main.get_world_chunk_context()`: adapter đọc, không mutate SceneTree, spawn state hoặc Save.

Content definition ID (`chunk.paloria_origin`) khác runtime coordinate key (`chunk.p0.p0`); không được dùng lẫn hai vai trò.

## Validation, compatibility và phần chưa làm

`validate_world_chunks.gd` phủ biên dương/âm, origin projection, key round-trip/rejection, typed canary/catalog và Main scene adapter. Content registry xác nhận 44 definitions cùng biome reference.

Save/data breaking change: none; chunk key chưa admit vào Save v1. Asset/provenance: none. Gameplay/world scene không đổi. U2.2 sẽ xây admission/unload quanh player và debug snapshot; spawn director, navigation, persistent delta vẫn ngoài scope.
