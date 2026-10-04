# Paloria 3.0 — kế hoạch cập nhật lớn

Ngày lập: 2026-10-04. Project: Godot 4.7.2, top-down 2D, pet/căn cứ/nông trại là vòng chơi chính.

## Hiện trạng có bằng chứng

- U0.1 ngày 2026-10-04 đã sửa lỗi `is_sprinting`; Godot 4.7.2 editor-load và main-scene smoke đều exit 0, không còn parse/script/resource error. Xem `docs/CHECKPOINT.md`.
- `player.gd` 1.086 dòng, `creature.gd` 1.054, `hud.gd` 411, `pet.gd` 410, `resource_node.gd` 388; nhiều dữ liệu, UI, input, combat và spawn nằm chung script.
- `hud.tscn` 924 dòng; UI có nhiều style inline, khó tái sử dụng và đổi giao diện đồng bộ.
- World hiện là `main.tscn` tĩnh với nền khoảng 3.200×3.200; chưa thấy TileMapLayer chunk streaming, navigation region, save/load hay input map.
- 166 file ảnh/âm thanh, khoảng 3,48 MiB đã có manifest SHA-256/reference; 0 file có provenance được xác minh nên tất cả vẫn quarantine. Có 3 nhóm trùng byte (18 file) và nhiều file `test_*` chưa dùng.
- Project đã có Git repository cục bộ, branch `main`, root commit `2c243e1`; tag `baseline-u0.3` là restore point trước refactor. Chưa cấu hình remote.

Không xóa gameplay hiện có trong một lần. Mỗi milestone là một vertical slice chạy được, có migration tạm nếu data format đổi.

U1.1 ngày 2026-10-04 đã tạo stable content ID, typed `ContentDefinition`/`ItemDefinition`, registry và `item.wood` canary. U1.2 nối `item.wood` vào luồng pickup/inventory bằng adapter; storage vẫn giữ legacy key để recipe/chest/HUD tương thích cho tới U1.4.

U1.3 đã bổ sung typed mirror cho recipe sphere, workbench và berry crop cùng cross-reference validation. Runtime dictionary/enum chưa đổi; inventory transaction và bootstrap catalog được giữ cho U1.4.

## Kiến trúc mục tiêu

```text
res://
  core/               event types, result/errors, game clock, deterministic RNG
  data/               custom Resources + .tres definitions
    creatures/ items/ recipes/ buildings/ crops/ biomes/
  actors/
    player/            controller, combat, needs, animation, interaction
    creatures/         wild AI, combat, capture, animation
    pets/              command, work, needs, progression, animation
  systems/
    inventory/ crafting/ building/ farming/ ranching/ combat/ save/
  world/
    zones/ chunks/ spawning/ navigation/ weather/
  ui/
    theme/ hud/ inventory/ pet_roster/ build_menu/ crafting/ settings/
  presentation/
    animation/ vfx/ audio/ camera/
  tests/
  assets/vendor/       package theo nguồn; không trộn file không rõ license
  assets/game/         asset đã chọn/normalize dùng trong scene
```

Quy tắc phụ thuộc: actor gọi component con; component phát signal lên orchestrator; UI đọc ViewModel/snapshot và phát intent, không sửa inventory/HP trực tiếp. Data cân bằng nằm trong typed `Resource`, không dùng tên tiếng Việt làm ID. ID ổn định dạng `item.wood`, còn localization là text riêng.

## Milestone U0 — ổn định baseline (1–2 ngày)

Tiến độ: U0.1–U0.4 đã hoàn tất: baseline/test, asset inventory/docs, Git restore point và action/priority cho 166 asset. Xác minh/thay thế provenance vẫn là công việc xuyên suốt U1–U4.

1. Khởi tạo Git và tag/snapshot baseline sau khi người dùng xác nhận; bỏ `.godot/` khỏi version control.
2. Sửa lỗi `is_sprinting`, chạy import headless và smoke main scene. Ghi warnings/errors thật.
3. Tạo asset manifest cho toàn bộ file hiện có: đường dẫn, SHA-256, kích thước, nguồn, tác giả, SPDX/license, trạng thái `verified/quarantine`.
4. Di chuyển `test_*`, preview và duplicate khỏi đường dùng production sau khi kiểm tra reference. Chưa xóa file ở milestone này.
5. Thêm test harness tối thiểu và lệnh `tools/check_project.ps1` cho parse/load main scene.

Gate: headless exit 0 không parse error; game vào main scene; baseline có thể phục hồi; không có asset mới thiếu license record.

## Milestone U1 — data và service boundaries (4–7 ngày)

- Tạo `CreatureDefinition`, `ItemDefinition`, `RecipeDefinition`, `BuildingDefinition`, `CropDefinition`, `BiomeDefinition` bằng custom Resource.
- Chuyển dictionary khỏi player/creature/buildings từng nhóm; thêm validator duplicate ID, missing texture, recipe cycle và số âm.
- Tách inventory/equipment, health/stamina/needs, interaction, combat stats, crafting và building placement khỏi `player.gd`.
- Tách creature brain, perception, locomotion, combat/capture, status effects khỏi `creature.gd`; mỗi state là strategy nhỏ hoặc state node.
- Tạo SaveGameService versioned, lưu ID/data thuần; không serialize Node/scene path làm save contract.

Gate: player và creature orchestrator mục tiêu <350 dòng mỗi file; data validation headless xanh; save → quit → load giữ inventory, pet roster, công trình và farm plot.

## Milestone U2 — world rộng và streaming (5–8 ngày)

- Dùng `TileMapLayer` theo chunk 256–512 px; chia biome starter meadow, forest, quarry, wetland và ruin.
- `WorldChunkManager` load bán kính quanh player, unload ngoài bán kính; persistent delta lưu resource node, crop, building, captured spawn.
- Spawn table theo biome/time/weather, budget toàn world và respawn rule; không scan `get_nodes_in_group()` mỗi frame.
- NavigationRegion2D theo chunk hoặc steering grid; pet không mắc công trình/farm/water.
- Camera bounds, minimap/fog-of-war, fast travel mở bằng khám phá.

Gate: di chuyển liên tục qua ≥9 chunks không hitch rõ; quay lại chunk giữ thay đổi; soak 20 phút không tăng node/memory vô hạn.

## Milestone U3 — UI/UX chuyên nghiệp (4–7 ngày)

- Một `Theme` và token màu/spacing/type scale; NinePatch/panel/button dùng lại, bỏ style inline dày đặc khỏi `hud.tscn`.
- HUD theo ngữ cảnh: HP/stamina và quickbar luôn hiện; hunger/thirst/status thu gọn; quest tracker collapsible; pet command wheel; interaction prompt theo input device.
- Màn hình Inventory + Equipment, Pet Roster/Detail, Build Catalog, Craft Queue, Farm/Ranch status, Map/Journal, Settings.
- Responsive anchors cho 16:9/16:10/Steam Deck; scale UI 80–150%, remap input, color-blind palettes, giảm screen shake/flash.
- Modal focus, gamepad navigation, pause semantics; UI phát intent, gameplay trả snapshot/result.

Gate: keyboard/mouse và gamepad hoàn thành capture → assign work → collect; không text tràn ở 1280×720 và 1920×1080; UI không chứa mutation gameplay.

## Milestone U4 — animation và hình ảnh (5–10 ngày)

- Chốt art bible: pixel grid 32×32 hoặc 48×48, palette, outline, shadow, light direction, tỷ lệ actor/building. Không trộn 16/32/64 px tùy tiện.
- Chuẩn animation: idle 4–6 frame, walk 6–8, run 8, attack anticipation/contact/recovery, tool use, throw, hurt, down/faint; pet thêm eat/sleep/work/celebrate.
- `AnimationPlayer` + `AnimationTree`/state machine; gameplay event đặt hit frame, VFX/SFX marker, animation không tự quyết damage.
- 4 hướng là baseline; 8 hướng chỉ dùng khi đủ ngân sách asset cho toàn bộ state. Mirror chỉ khi vũ khí/ánh sáng không bất đối xứng.
- Camera/VFX service: hit-stop ngắn, shake theo cường độ, particles pooling, outline target, build ghost hợp lệ/không hợp lệ, weather overlays.

Gate: không popping khi chuyển locomotion/action; hit frame khớp damage; 20 actor on-screen giữ target frame budget; có option giảm motion.

## Featured initiative AT — Paloria Luminous Town

Sau khi U2 có chunk/persistence contract ổn định, triển khai sáng kiến thị trấn anime nguyên bản xuyên U2–U4:

- Thị trấn Nhật Bản hư cấu gồm ga/phố chợ, khu dân cư sườn dốc, đền/đài quan sát, bờ nước, nông trại và rừng/mỏ.
- Lấy cảm giác bầu trời, hoàng hôn, mưa và khoảng lặng anime điện ảnh làm mood; không sao chép địa điểm, frame, nhân vật, soundtrack hoặc sprite của “Your Name”.
- Greybox 3×3 chunk và gameplay anchor trước; sau đó mới admit asset, lighting/weather, thay player/pet, audio state và mở rộng toàn town.
- Player/pet production dùng art gốc theo art bible; asset mạng chỉ vào project qua license/provenance/hash gate.
- Nhạc CC0 chỉ dùng prototype; release cần soundtrack gốc hoặc bộ track đã xác minh và credits thống nhất.

Kế hoạch, district layout, candidate và gate: docs/roadmap/ANIME_TOWN_RENEWAL.md.
## Milestone U5 — gameplay pet/base sâu hơn (8–14 ngày)

- Pet: trait, work suitability, stamina, hunger, mood, bond; stance Follow/Guard/Focus/Work/Recall; command queue có lý do thất bại rõ.
- Công việc: job board và reservation, pet lấy input từ storage → đi tới station → làm → gửi output; không sinh nguyên liệu miễn phí.
- Farming: soil fertility, moisture, crop requirements, season/weather bonus, pests; tưới/bón/thu hoạch có tool và automation pet.
- Ranching: feed trough, rest, produce cycle, pairing/breeding ở phase sau; tránh hệ gene trước khi loop chăn nuôi vui.
- Building: grid/socket placement, collision/terrain validation, dismantle/refund, storage/logistics, repair và durability có mục đích.
- Combat: pet skill loadout, elemental reaction/status, telegraph enemy, dodge/guard, break/stagger, boss cần đổi pet/command; player hỗ trợ thay vì tăng damage vô hạn.
- Progression: research tree mở recipe/biome/command; quest hướng dẫn hệ thống, không chỉ checklist tài nguyên.

Gate: một vòng 30 phút gồm khám phá → đánh yếu → bắt pet → đưa về base → giao việc → dùng output mở công nghệ → vượt encounter mới; không có duplication/loss trong inventory/job.

## Milestone U6 — persistence, balance và release quality (5–8 ngày)

- Save schema version + migration + backup; autosave không chặn frame, atomic replace file và recovery khi save hỏng.
- Telemetry local dev: frame time, active actor, path requests, chunk load, object pool, job queue; không thu thập dữ liệu người dùng khi chưa có consent.
- Balance spreadsheet/export → Resources; deterministic simulation tests cho recipe economy, crop yields, capture odds, work throughput.
- Audio buses, music transitions, pooling, localization VI/EN, credits/licenses screen.
- Export Windows debug/release, controller smoke, 60-minute soak, bug triage theo severity.

Gate: save compatibility test, no parse/runtime error, frame target được đo trên cấu hình mục tiêu, license manifest đầy đủ.

## Backlog sau vertical slice

Multiplayer/Java backend chỉ mở lại khi single-player state ownership, save schema và command model ổn định. Co-op cần authority/reconciliation riêng; không nối trực tiếp prototype Godot vào backend cũ trước ADR. Các hệ gene phức tạp, trading, PvP, guild và procedural world vô hạn là hậu kỳ.

## Cách chia việc cho agent

Mỗi lượt chỉ nhận một work package 0,5–2 ngày: issue cụ thể → regression/check trước → thay đổi → headless/smoke → checkpoint. Agent phải ghi file sửa, lệnh và log, phần chưa kiểm chứng, data/wire/save breaking change, bước đầu tiếp theo. Không dùng số lượng feature hoặc scene để tuyên bố phase hoàn tất.
