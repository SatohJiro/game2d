# AI AGENT CODING STANDARDS & GAME DEV RULES

Đọc `docs/INDEX.md`, `docs/CHECKPOINT.md`, tài liệu module/feature liên quan và `.agents/rules/game_development.md` trước khi sửa. Roadmap được chia theo milestone/gate; mỗi lượt chỉ làm một work package nhỏ và cập nhật checkpoint.

## Baseline và kiểm chứng

- Godot chuẩn hiện tại: 4.7.2. Dùng executable console trong `D:\desktop\Godot_v4.7.2-stable_win64.exe` nếu `godot` chưa có PATH.
- Trước và sau thay đổi GDScript/scene, chạy headless import/load. Không báo xanh nếu log còn `SCRIPT ERROR`, `Parse Error`, missing dependency hoặc invalid node path.
- Baseline U0.2 ngày 2026-10-04 đã xanh asset-integrity, editor-load và main-scene smoke; xem `docs/CHECKPOINT.md`. Chạy lại `tools/check_project.ps1` sau mỗi thay đổi code/scene/asset.
- Không xóa/đổi hàng loạt asset/scene trước khi có Git snapshot hoặc backup được kiểm tra.

## Kiến trúc bắt buộc

- Scene tự chứa; call down, signal up. UI phát intent và render snapshot/ViewModel, không trừ item/HP hay đổi Node gameplay trực tiếp.
- Dữ liệu species/item/recipe/building/crop/biome phải dùng typed custom `Resource` và ID ổn định; tên hiển thị qua localization, không dùng text tiếng Việt làm khóa lưu trữ.
- Tách input, locomotion, combat, interaction, inventory, building, save và presentation. Không thêm feature mới vào các god scripts `player.gd`, `creature.gd`, `hud.gd` nếu chưa tách boundary liên quan.
- Logic damage/capture/job/inventory phải deterministic và testable ngoài animation. Animation/VFX nhận event, không quyết định kết quả gameplay.
- World rộng dùng chunk admission/unload và persistent delta. Không tạo world vô hạn bằng một scene khổng lồ hoặc scan toàn bộ group mỗi frame.
- Save có schema version và migration; không serialize Node, Callable hoặc scene instance làm contract.

## UI, animation và accessibility

- Một Theme/tokens dùng chung; responsive anchors/containers; keyboard, mouse và gamepad navigation; focus và pause rõ ràng.
- Hỗ trợ UI scale, remap input, giảm flash/shake/motion và palette phân biệt trạng thái không chỉ bằng màu.
- Chuẩn hóa pixel grid, frame naming, FPS và state transitions trong art bible. Nearest filtering và integer scaling; không mix pack khác style khi chưa normalize.
- Gameplay hit/cast phải có anticipation, contact marker, recovery; SFX/VFX gắn marker. Dùng AnimationTree khi actor có nhiều state, không tạo chuỗi boolean animation mới.

## Asset, nghiên cứu mạng và bản quyền

- Có thể tìm tài liệu/asset online khi task yêu cầu; ưu tiên Godot docs, trang tác giả và nguồn chính thức. Ghi URL và ngày truy cập trong docs/receipt.
- Không tải hoặc dùng asset nếu chưa xác minh license. Không dùng sprite Pokémon, Palworld hoặc IP bên thứ ba làm content phát hành.
- Mọi asset ngoài phải có provenance + SHA-256 + license/SPDX + intended use. Source bất biến ở `assets/vendor/<package>`; derivative ở `assets/game`; không ghi đè source.
- Candidate search không phải admission. Phải review style/animation coverage, import headless và human visual review trước khi scene production tham chiếu.
- `game-dev` CLI là quy trình ưu tiên cho package/vendoring. Nếu thiếu CLI, dừng bước download/admission và ghi blocker; không copy loose file để lách kiểm tra.

## Kỹ năng agent cần áp dụng

- Godot 4.7 GDScript static typing, SceneTree lifecycle, signals, custom Resource, TileMapLayer, NavigationServer2D, AnimationPlayer/AnimationTree, UI Theme/Container và profiler.
- Game architecture: component/state machine, data-driven content, command/result, save migration, deterministic simulation, object pooling và chunk streaming.
- Game design: economy conservation, pet work scheduling/reservation, combat telegraph, progression pacing, farming/ranch feedback loops và accessibility.
- Art pipeline: sprite sheet/frame audit, pixel grid/palette, animation timing, texture import, VFX/SFX sync, license/provenance/hash.
- Verification: headless import/load, focused regression, smoke vertical slice, memory/frame-time measurement. Không tối ưu dựa cảm giác khi chưa có baseline metric.

## Checkpoint sau mỗi work package

Ghi mục tiêu/invariant; file sửa; test/lệnh/log; save/data breaking change; asset provenance; phần chưa kiểm chứng; bước đầu tiếp theo. Không ghi “hoàn tất phase” khi gate trong roadmap chưa đạt.

Áp dụng `docs/process/DOCUMENTATION_STANDARD.md`: đổi module/API phải cập nhật `docs/architecture/MODULES.md`; đổi luật/input/reward phải cập nhật `docs/gameplay/FEATURES.md`; đổi dependency/gate phải cập nhật roadmap. Dùng `docs/process/WORK_PACKAGE_TEMPLATE.md` cho package mới. Trạng thái không được chỉ tồn tại trong hội thoại.

Dự án này áp dụng các nguyên tắc phát triển game 2D với **Godot 4.x**:

1. **Kiến trúc**:
   - Áp dụng triệt để "Call Down, Signal Up".
   - Tự chứa (Self-contained scenes), kiểm tra phòng vệ `is_instance_valid()`, `is_inside_tree()`.
   - Phân tách rõ ràng Gameplay và UI/HUD.
2. **Game Feel (Juice)**:
   - Hit flash, screen shake, floating damage numbers, squash & stretch tweens.
   - Trực quan hóa tỉ lệ bắt quái (Catch Rate Indicator), hiệu ứng rung lắc của Cầu Thu Phục (Pal Sphere).
3. **Tối ưu hóa**:
   - Phân chia `_physics_process` cho chuyển động/va chạm và `_process` cho hoạt họa/visual.
   - Quy hoạch chuẩn Collision Layer (1: Player, 2: Creatures/Pet, 3: World/Resources, 4: Projectiles/Spheres).
   - Dọn dẹp đối tượng bằng `queue_free()`.
4. **Kiểm tra tự động**:
   - Chạy `godot --headless --check-only` sau mỗi lần cập nhật mã nguồn để đảm bảo không có lỗi runtime.
