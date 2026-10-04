# Prompt cho model tiếp theo — U1.8a Creature perception boundary

Bạn đang tiếp tục Godot 4.7.2 project Paloria 3.0. Làm đúng một work package nhỏ: U1.8a. Đọc `AGENTS.md`, `.agents/rules/game_development.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, `docs/architecture/MODULES.md`, `docs/gameplay/FEATURES.md`, `docs/roadmap/IMPLEMENTATION_PHASES.md` và `docs/roadmap/ANIME_TOWN_RENEWAL.md` trước khi sửa.

## Mục tiêu

Tách quyết định perception/target acquisition của WildCreature khỏi vòng physics dày đặc, có cadence rõ và logic thuần có thể test. Package này chuẩn bị cho FSM U1.8b; không viết lại toàn bộ `creature.gd` trong một lượt.

## Phạm vi bắt buộc

1. Chạy `tools/check_project.ps1` để xác nhận baseline, rồi audit có bằng chứng:
   - mọi `_physics_process`, `_process`, timer và state branch trong `scripts/creature.gd`;
   - `get_nodes_in_group`, Area2D overlap, distance scan và target assignment;
   - ai ghi `state`, `target`, `velocity`, attack/capture/sleep/defeat guard;
   - call path từ `main.tscn`/spawner tới creature setup.
2. Ghi current-state table: state, perception cần thiết, transition owner, locomotion owner và side effect. Không đổi behavior khi chưa có bảng.
3. Tạo boundary nhỏ trong `systems/creature/`:
   - typed/ref-counted perception input snapshot;
   - deterministic target/transition decision result;
   - pure policy không truy cập SceneTree/Node/RNG.
4. Node adapter chỉ thu thập candidate ở cadence hữu hạn hoặc từ Area2D/event, chuyển dữ liệu tối thiểu vào policy. Không scan toàn bộ group mỗi physics frame.
5. Giữ nguyên combat/capture contract U1.5/U1.7, stable species snapshot và ownership lifecycle. CAPTURING, SLEEP, STUN và defeated không được bị perception ghi đè.
6. Chỉ một owner ghi target/state trong phần đã migrate. Nếu chưa thể migrate mọi state, tạo compatibility adapter rõ và liệt kê path còn legacy.
7. Regression tối thiểu:
   - cadence không query trước hạn và query đúng khi đến hạn;
   - candidate sorting/tie-break deterministic;
   - out-of-range/invalid candidate bị loại;
   - protected states không đổi target/state;
   - target lost/acquired behavior giữ tương thích;
   - capture rejection vẫn resume an toàn;
   - main scene load/smoke xanh.
8. Cập nhật tài liệu module, gameplay, roadmap, checkpoint và prompt U1.8b. Ghi metric trước/sau: số group scan hoặc perception query trong một khoảng simulation cố định.

## Giới hạn

- Không triển khai skill/drop U1.9, PetInstance U1.10, save U1.11, chunk streaming U2 hoặc map/art/audio.
- Không đổi balance, sprite, animation, collision layer hoặc scene hierarchy nếu không cần cho boundary.
- Không tạo service/global singleton lớn và không thêm logic mới vào `player.gd`.
- Không dùng display name, array index, asset path hoặc scene path làm identity.
- Không tuyên bố performance tốt hơn nếu chưa có metric tái lập.

## Definition of Done

- Pure perception policy và adapter có static typing, không có parse/runtime warning.
- Focused regression chứng minh cadence, determinism, state guards và behavior adapter.
- Full `tools/check_project.ps1` xanh; quét mọi `build/checks/*.log` không có script/parse/missing dependency/error/leak.
- `git diff --check` xanh; tài liệu ghi save/data compatibility, asset impact, rollback, manual gaps.
- Commit trên branch riêng rồi fast-forward `main` khi gate xanh.

## Hướng sản phẩm phải bảo toàn

Paloria Luminous Town vẫn là initiative nổi bật cho U2–U4. Kiến trúc perception phải phù hợp world chunk admission/unload sau này: không giữ Node ngoài chunk như dữ liệu bền vững và không phụ thuộc scan toàn world. Your Name chỉ là mood reference; content phát hành phải nguyên bản và có license/provenance hợp lệ.
