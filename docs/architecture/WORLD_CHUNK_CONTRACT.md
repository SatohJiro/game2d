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

## U2.2 — admission foundation

`ChunkAdmissionPolicy` tạo tập 3×3 (radius 1) quanh center và trả `ChunkAdmissionDelta` với danh sách key lexical deterministic. `ChunkAdmissionCoordinator` sở hữu active records cùng monotonic revision: lần đầu admit 9; di chuyển trong cùng chunk là no-op; crossing một cạnh admit 3 rồi unload 3, luôn giữ 9 record. Coordinator commit admit trước unload để adapter scene tương lai không tạo lỗ tạm thời quanh player.

Request mang observed revision; stale revision, duplicate/invalid active key hoặc world position non-finite không mutate. Main cập nhật coordinator từ vị trí player nhưng chưa instantiate/queue-free chunk scene. `get_chunk_admission_debug_snapshot()` trả deep detached dictionary gồm center, revision và active records; đây là telemetry read-only, không phải save DTO hay UI ViewModel cuối.

Regression phủ initial 3×3, signed corners, stable ordering, same-chunk no-op, positive crossing, stale/duplicate failure atomicity và detached Main snapshot. Save/data, world content, creature spawn, navigation và asset không đổi.

## U2.3 — persistent chunk delta foundation

`ChunkDeltaEnvelope` nhóm building/resource record theo canonical chunk key và coordinate, mỗi entry giữ stable kind/instance ID, world position và typed legacy payload. `ChunkDeltaProjector` dùng floor-boundary U2.1, sort chunk/entity deterministic và flatten ngược về typed records cho apply.

Save v1 thêm optional `world.chunk_deltas`. Snapshot project từ live building transform và resource-node position; apply ưu tiên envelope khi có, save cũ thiếu field fallback về `entity_deltas/resource_deltas`. Toàn bộ envelope được validate trước commit: key/coordinate/position phải khớp, identity unique toàn cục, payload typed hợp lệ. JSON integral normalization chỉ nằm ở envelope parse để giữ typed integer state sau JSON round-trip.

Shape Save v1 pre-release được mở rộng nhưng version giữ 1 và legacy fallback rõ ràng. Ambient creature không persist; scene streaming/spawn/navigation không đổi.

## U2.2b — placeholder scene admission closure

`ChunkSceneAdapter` áp accepted delta vào container riêng: stage/admit placeholder trước, sau đó queue-free unload; revision stale, duplicate admission hoặc missing unload fail closed. `chunk_placeholder.tscn` tự chứa, mang key/coordinate/revision và đặt tại `ChunkCoordinate.world_origin()`. Main giữ reference map, không scan SceneTree mỗi frame; exit cleanup toàn bộ placeholder.

Runtime luôn có đúng 9 placeholder records/Nodes quanh player sau frame cleanup. Chúng chỉ vẽ border debug, không sở hữu Environment/content/collision/navigation/spawn. `ChunkDebugOverlay` mặc định ẩn, F8/API toggle và render deep snapshot gồm center/revision/count; presentation không mutate coordinator.

## U2.4 — navigation region lifecycle

`ChunkNavigationRequest/Result` là typed command boundary cho hai thao tác: đồng bộ region theo một accepted admission delta, hoặc cập nhật trạng thái obstacle placeholder. `ChunkNavigationAdapter` sở hữu duy nhất map `chunk_key → region RID`; Main chuyển delta sang request sau khi scene adapter nhận cùng revision. Initial admission tạo 9 region hình chữ nhật inset 2 world units trong biên chunk để tránh raster edge overlap, crossing chỉ tạo/free ownership khác biệt, còn same-chunk no-op không gọi server hoặc churn RID.

Sync chỉ nhận revision kế tiếp và exact projected key set. Stale revision, duplicate key, missing unload, invalid coordinate hoặc revision gap đều fail trước khi mutate. Obstacle update hiện là contract tối thiểu `blocked` bật/tắt toàn region, có monotonic per-chunk revision; duplicate/stale và inactive key không mutate. Polygon obstacle chi tiết, terrain bake và path request vẫn ngoài scope.

Unload tách region khỏi map rồi `free_rid`; Main cleanup toàn bộ region khi exit. Debug snapshot chỉ chứa stable key, coordinate, obstacle state/revision và create/free counters, không chứa RID. Navigation state không vào Save v1; static Environment, creature spawn và gameplay locomotion không đổi.

## U2.5 — ambient spawn director foundation

`AmbientSpawnRequest/Result/Spec` và `AmbientSpawnPolicy` tách quyết định population khỏi Main. Input gồm center, exact active chunk keys, owned ambient identity→chunk snapshot, biome ID, bốn time bucket, budget, injected seed và chunk revision. Policy ưu tiên center rồi Manhattan distance/lexical key, tối đa hai slot mỗi chunk, và resolve stable species/position/level không dùng global RNG. Full population giữ nguyên identity khi time/seed đổi; chỉ slot thiếu mới được resolve, nên timer same-chunk không reroll.

Identity runtime dùng `ambient.<signed_coordinate>_s<slot>`, ví dụ `ambient.p0_p0_s0`; đây không phải content definition hay Save identity. Dragon bị loại khỏi ambient allowlist. `AmbientSpawnAdapter` là owner duy nhất của registry ambient Node, không scan children/SceneTree để tính budget; boss và night raid vẫn thuộc owner riêng và không tiêu budget. Crossing queue-free owned actor ở chunk inactive rồi fill lại đúng budget trong active set; stale/gapped revision, duplicate key hoặc malformed identity/chunk fail trước mutation.

Ambient population vẫn transient và không vào Save v1. Package chưa có cooldown cho captured/defeated slot, spawn point authored, per-biome weighted table hoặc distance culling ngoài admission 3×3; các phần này cần persistent spawn delta trước khi release.

## U2.6 — discovery/fog data contract

`ChunkDiscoveryState` sở hữu tập canonical runtime chunk keys đã enter và monotonic revision; `ChunkDiscoveryRequest/Result` áp optimistic revision guard. Chỉ center của một accepted admission change được discover. Tám neighbor active phục vụ streaming vẫn fog cho tới khi chính chúng trở thành center; same-chunk no-op không gọi mutation và duplicate discovery không tăng revision. Invalid/noncanonical key hoặc stale revision fail trước mutation.

`ChunkDiscoveryAdapter` là boundary mỏng của Main. `create_view_snapshot()` trả deep-detached union giữa mọi discovered tile và active 3×3, với key/coordinate cùng cờ `discovered`, `active`, `current`; snapshot không giữ Node, Resource, Callable hoặc RID và chưa phải HUD ViewModel cuối. Discovery không mutate scene, navigation hay spawn ownership.

State có JSON-safe DTO `{revision, discovered_chunks}` với lexical keys, JSON integer normalization, duplicate/key/revision-count guards và legacy missing/empty fallback về state rỗng. Save v1 chưa đổi: coverage audit ghi discovery là state progression mới cần admission riêng trước khi fast travel dựa vào nó. Minimap art/UI, fog renderer và fast travel ngoài scope.

### U2.6b Save admission

`world.discovery_state` nay round-trip qua Save v1 snapshot/schema/apply/coordinator. Main chỉ import typed result sau `is_loaded()`, nên corrupt repository, invalid DTO và apply failure giữ state runtime. Load thành công restore exact discovered set nhưng không đổi current admission center, active scene/navigation region hay ambient registry. Legacy save thiếu field restore state rỗng. Fast travel vẫn chưa dùng contract này.
