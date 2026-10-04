# Sáng kiến Featured World — Thị trấn anime nguyên bản

Trạng thái: PLANNED
Ngày ghi nhận: 2026-10-04
Phạm vi: U2 world streaming, U3 UI/map, U4 art-animation-audio, U5 gameplay integration.

## Ý định sản phẩm

Xây một thị trấn Nhật Bản hư cấu có cảm giác anime điện ảnh: bầu trời rộng, hoàng hôn rực, trời sao sâu, mưa phản chiếu, phố dốc và các khoảng lặng giàu cảm xúc. “Your Name” là tham chiếu cảm xúc do người dùng cung cấp, không phải blueprint để sao chép.

Bản phát hành phải có địa lý, kiến trúc, nhân vật, pet, biểu tượng và nhạc riêng của Paloria. Không tái dựng địa điểm, khung hình, nhân vật, logo, soundtrack hoặc sprite nhận diện được từ phim hay IP khác.

## Mục tiêu trải nghiệm

- Người chơi nhận ra thị trấn từ silhouette và tuyến đường sau 10–15 phút.
- Mỗi quận phục vụ ít nhất một vòng gameplay: khám phá, bắt pet, farming, job, crafting, combat hoặc social quest.
- Chuyển ngày → hoàng hôn → đêm tạo thay đổi thị giác, âm thanh và spawn mà không cản đọc gameplay.
- Base/farm hòa vào thị trấn và vùng ven, không trở thành một menu tách biệt.
- Player và pet có silhouette, palette, shadow, animation timing thống nhất với world.
- Cảnh đẹp không làm giảm khả năng đọc collision, interactable, telegraph và build placement.

## Art direction đề xuất

Tên nội bộ: Paloria Luminous Town.

- Góc nhìn top-down 2D, tạo chiều sâu bằng Y-sort, foreground occluder và parallax.
- Grid gameplay 32×32; actor có thể dùng canvas 48×64 hoặc 64×64 nhưng chân bám grid 32.
- Pixel art chi tiết hoặc raster-to-pixel được normalize; không trộn sprite 16×16, 32×32 và HD trực tiếp.
- Ánh sáng trên-trái nhất quán; rim light chỉ dùng ở hoàng hôn/đêm.
- Sáng dùng xanh lam nhạt và xanh lá ấm; trưa ưu tiên readability; hoàng hôn dùng cam/hồng/tím; đêm dùng indigo với đèn vàng; mưa giảm saturation và thêm ripple/reflection có giới hạn.
- Motif nguyên bản: sao rơi Paloria, tinh thể Pal, dây điện, chuông gió, tàu địa phương, ruộng và đền quan sát bầu trời.

Art bible U4 phải chốt palette, grid, outline, shadow, light direction, frame naming, FPS và import preset trước khi thay asset runtime hàng loạt.

## Bố cục world và quận

### Quảng trường ga và phố chợ

- Điểm vào thị trấn, fast travel, shop/craft service, bulletin board, NPC schedule và quest hub.
- Đường ray tạo ranh giới chunk; tàu chạy theo event, không gây collision bất ngờ.
- Landmark dùng tháp đồng hồ và canopy ga mang biểu tượng Paloria gốc.

### Khu dân cư trên sườn dốc

- Hẻm, bậc thang, mái nhà, máy bán hàng, sân chơi và dây điện.
- Pet social encounter, lost-item quest, rooftop collectible và shortcut.
- Occluder fade khi che actor; ngõ cụt luôn có reward hoặc storytelling.

### Đền và đài quan sát trên đồi

- Vista hoàng hôn/trời sao, story beat và rare pet spawn.
- Kiến trúc đền thiết kế riêng, không sao chép landmark hoặc bố cục từ phim.
- Festival state theo quest, lantern route và boss/ritual arena đọc rõ telegraph.

### Bờ hồ/sông và cầu đi bộ

- Fishing, water-pet habitat, weather reflection và quiet exploration.
- Collision contour ổn định; pet navigation không đi vào vùng cấm.
- Cầu đủ rộng cho player và companion.

### Vùng ven nông trại

- Farming/ranching nối với economy thị trấn.
- Ruộng, greenhouse, barn, feed route, storage logistics và build parcels.
- Pet worker đi theo navigation chunk và reservation system.

### Rừng và mỏ ngoài thị trấn

- Capture/combat/resource có độ nguy hiểm tăng.
- Palette và ambience chuyển dần; có ít nhất hai đường về town.

## Thứ tự triển khai

### AT0 — concept và reference board

- Chốt original shape language, palette, grid và danh sách điều cấm sao chép.
- Vẽ sơ đồ quận, vista, critical path và gameplay anchor.
- Cảnh thử: ga → phố dốc → đền trên đồi.
- Gate: đạt cảm giác anime luminous Paloria nhưng không nhận diện như bản sao địa điểm/IP cụ thể.

### AT1 — U2 greybox và streaming

- Tạo WorldChunkManager/ChunkDefinition trước.
- Greybox 3×3 chunk, camera bounds, Y-sort, occluder và navigation.
- Đặt habitat, resource node, building parcel và farm edge bằng marker data.
- Gate: đi qua 9 chunk, quay lại giữ delta, pet không mắc đường dốc/cầu/công trình.

### AT2 — asset proof of concept

- Admit đúng một terrain/prop package đã xác minh vào assets/vendor.
- Normalize subset vào assets/game, không ghi đè source.
- Dựng một block phố, một mái nhà, một cầu, một cụm cây và một water edge.
- Gate: art review 720p/1080p; grid, palette, shadow và collision nhất quán.

### AT3 — lighting, weather và sky identity

- Day/night palette controller, cloud/parallax, star field, rain/ripple/reflection.
- Light mask cho cửa sổ, đèn đường, lantern; hỗ trợ reduced motion/flash.
- Weather trình bày state deterministic, không tự thay reward/spawn.
- Gate: interaction/collision/telegraph vẫn rõ; frame time được đo.

### AT4 — player và pet visual replacement

- Vẽ lại player và một pet hero trước, giữ gameplay contract.
- Player: idle, walk, run, roll, attack, throw, tool, hurt, down.
- Pet: idle, move, attack, hurt, down, eat, sleep, work, celebrate.
- Animation nhận event domain; không tự quyết damage/capture/job.
- Gate: không missing frame/pop, hướng nhìn nhất quán, silhouette rõ ở mọi thời điểm.

### AT5 — audio identity

- Music state: day town, dusk vista, night town, rain, shrine/story, outskirts danger.
- Bus: Music, Ambience, SFX, UI; crossfade theo zone/time/weather.
- Ambience: gió, chim, ve, tàu xa, nước, mưa, festival; giới hạn voice/pooling.
- CC0 track chỉ là prototype; release dùng soundtrack gốc hoặc bộ track có provenance thống nhất.
- Gate: loop/crossfade không click, pause/settings đúng, volume riêng và không leak playback.

### AT6 — full district production

- Mở rộng từng quận sau khi AT1–AT5 đạt.
- Mỗi quận có gameplay anchor, spawn table, ambience profile, minimap label và save delta.
- Replace legacy main scene theo từng chunk, luôn giữ build chạy được.
- Gate: core loop 30–45 phút xuyên town/outskirts; không còn asset runtime UNKNOWN trong slice.

### AT7 — polish và cinematic moments

- Vista framing, foreground petals/leaves, camera easing, festival lighting và story staging.
- Cutscene có skip/reduced motion.
- Screenshot checklist cho sáng, trưa, hoàng hôn, đêm và mưa.
- Gate: visual review, accessibility, controller traversal, performance soak và license audit.

## Candidate asset đã nghiên cứu

Các mục này là candidate, chưa tải và chưa được admit.

| Package | Vai trò | License quan sát | Fit/rủi ro | Nguồn |
|---|---|---|---|---|
| PixelKensei Feudal Japan Props Vol.2 | cầu, cổng, bậc đá và shrine props 32×32 | CC0 trên trang tác giả | Fit grid; coverage nhỏ, cần review hiện đại vs phong kiến | https://pixelkensei.itch.io/feudal-japan-props-vol2-free-pixel-art-assets |
| Kenney Tiny Town 1.1 | greybox town/overworld | CC0, 16×16, 130 file | Chỉ prototype; phải upscale/normalize | https://kenney.nl/assets/tiny-town |
| JRPG Pack 2 Towns — Juhani Junkala | town music prototype | CC0 | Cần nghe, kiểm tra loop/peak và receipt | https://opengameart.org/content/jrpg-pack-2-towns |
| Emotional Piano — Centurion_of_war | vista/story prototype | CC0 | Kiểm tra loudness và loop | https://opengameart.org/content/emotional-piano-0 |
| Sunset Plains — Yoiyami | outskirts/dusk prototype | CC0 | WAV 63.3 MB; cần OGG derivative | https://opengameart.org/content/sunset-plains |
| Sakura Shrine Village — bubbabba | tham khảo coverage/prototype trả phí | custom commercial-use terms; AI-assisted | Cần người dùng mua, receipt và chấp nhận AI-assisted | https://bubbabba.itch.io/sakura-shrine-village |

Không dùng candidate “town theme 1” do trang nguồn từng ghi nhận vấn đề ảnh preview không rõ quyền, dù tác giả nói nhạc tự sáng tác.

Player/pet production nên là art gốc theo art bible. Có thể dùng image generation cho concept/base rồi làm sạch frame, silhouette và animation; phải lưu prompt, source image, model/output receipt và derivative recipe.

## Download và admission

1. Tra game-dev catalog list/show nếu package có trong catalog.
2. Tạo canonical package ngoài runtime với source page, download URL, author, version, SPDX/license, ngày truy cập và SHA-256.
3. Chạy game-dev package verify ngay trước admission.
4. Dry-run game-dev vendor admit vào assets/vendor/package_id.
5. Chỉ admit có confirm sau khi người dùng duyệt package, license và destination cụ thể.
6. Giữ license/readme nguyên bản; derivative sang assets/game/domain.
7. Regenerate inventory, ghi provenance override, headless import và visual review.
8. Package paid cần purchase/receipt của người dùng; không vượt paywall.
9. Không copy loose download trực tiếp vào assets/game.

Blocker hiện tại: game-dev CLI chưa có trong PATH ngày 2026-10-04. Chưa tải asset nào trong package roadmap này.

## Audio contract dự kiến

- Stable cue ID: music.town.day, music.town.dusk, music.town.night, music.town.rain, music.shrine.story, music.outskirts.danger.
- Zone/time/weather gửi MusicContext snapshot; AudioDirector chọn cue và crossfade.
- Gameplay code không gọi file path hoặc title bài nhạc.
- Track Resource chứa source ID, loop start/end, gain, tags và attribution ID.
- Save chỉ lưu world time/weather; không lưu playback object.
- Thiếu cue thì fallback ambience/im lặng, không crash.

## Gameplay integration

- Ga mở fast travel theo discovery.
- Chợ tiêu thụ output farm/crafting và tạo economy sink.
- Đền mở rare capture/story encounter bằng điều kiện typed.
- Bờ nước tạo fishing/water-pet job.
- Nông trại là khu build/automation có parcel rõ.
- Rừng/mỏ cung cấp combat/resource progression.
- Pet traversal, work reservation và return-to-owner hoạt động qua chunk boundary.
- NPC schedule/festival chỉ bắt đầu sau Save v1 để không tạo state không lưu được.

## Performance và accessibility

- Không tạo town bằng một scene khổng lồ; dùng chunk admission/unload.
- TileMapLayer tách ground, decoration, collision và foreground.
- Parallax/weather/reflection có quality tier và có thể tắt.
- Pool particles/ambient emitters; không tạo audio player mỗi event.
- Giảm motion/shake/flash; trạng thái không chỉ phân biệt bằng màu.
- Đo frame time, node count, texture memory, path request và audio voices trên scenario cố định.

## Definition of Done

- Map là thiết kế Paloria nguyên bản, không chứa asset/IP không được phép.
- Town slice 3×3 chunk có streaming, persistence, navigation và gameplay anchors.
- Player và một pet có animation coverage chuẩn, chung art direction.
- Day/dusk/night/rain đạt visual review, readability và accessibility.
- Music/ambience có stable cue contract, mix bus và clean transition.
- Mọi runtime asset trong slice là VERIFIED hoặc original với receipt/hash.
- Full project gate, traversal smoke, 20-minute soak và manual visual/audio review đạt.

## Ngoài phạm vi hiện tại

- Chưa download/admit asset hoặc mua package.
- Chưa thay main.tscn, player, pet hay audio runtime.
- U1.7 đã hoàn tất; không đổi thứ tự U1.8–U1.11. Initiative bắt đầu khi U2 world contract đủ ổn định.
