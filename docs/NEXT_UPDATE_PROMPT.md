# Prompt triển khai package U1.7c

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, `.agents/rules/game_development.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, roadmap, `CAPTURE_CONTRACT.md`, `DATA_CONTRACTS.md`, `DOMAIN_DEFINITIONS.md`, `MODULES.md` và gameplay G03/G06. Chạy `tools/check_project.ps1` trước khi sửa.

U1.7a deterministic capture và U1.7b sphere transaction đã VERIFIED. Chỉ thực hiện U1.7c roster ownership commit:

1. Audit có bằng chứng các path `Player.on_pet_captured`, `WildCreature.capture_succeeded`, `pet_party`, `active_pet`, `swap_active_pet` và dữ liệu species legacy. Ghi rõ current ownership và lifecycle trước khi đổi.
2. Chuẩn hóa stable species ID ở capture boundary. Nếu chưa thể tạo full typed `CreatureDefinition`, dùng mapping compatibility có kiểm thử cho species hiện hữu; không dùng display name, index, asset path hoặc scene path làm identity mới.
3. Tạo pure request/result cho roster admission/ownership. Input tối thiểu gồm stable species ID, snapshot stat/level và các roll đã inject; result phải phân biệt accepted/rejected/invalid/duplicate đủ để caller quyết định despawn.
4. Tách RNG khỏi commit: Player/caller lấy rarity roll và trait-choice input đúng một lần, pure resolver tính rarity/multiplier/trait. Tween, notification và Node lifecycle không quyết định kết quả.
5. `Player.on_pet_captured` phải trả typed result hoặc trạng thái rõ. Append party, reward EXP và quest progress chỉ xảy ra một lần trong accepted commit; reject/duplicate không cấp reward và không đổi roster.
6. `WildCreature.capture_succeeded` chỉ `queue_free()` sau accepted ownership commit. Khi reject, thoát trạng thái capture theo contract an toàn và giữ creature trong world. Thêm re-entry/duplicate guard để callback lặp không sở hữu hay thưởng hai lần.
7. Giữ `pet_party` legacy dictionary và summon Node adapter nếu cần tương thích. Không triển khai full persistent `PetInstance`, save migration, party capacity, command UI, worker jobs hay refactor summon trong package này; các phần đó thuộc U1.10/G06.
8. Regression bắt buộc: mapping species known/unknown; deterministic rarity/trait với boundary rolls; accepted append/reward đúng một lần; invalid/duplicate/rejected không mutation; reject không despawn; accepted despawn; callback lặp không double reward; main-scene adapter.
9. Cập nhật `CAPTURE_CONTRACT.md`, data/module docs, G03/G06, roadmap, INDEX, CHECKPOINT và prompt package kế tiếp. Ghi rõ save compatibility, adapter, rollback và manual capture/summon checks.

Giữ một work package nhỏ. Kết thúc bằng full `tools/check_project.ps1`, quét log không có `SCRIPT ERROR`, `ERROR`, parse/missing dependency/leak, chạy `git diff --check`, commit branch riêng và fast-forward `main` nếu mọi gate xanh.

## Hiện trạng cần biết

- `Player.pet_party` hiện là `Array[Dictionary]`; `active_pet` là Node.
- `on_pet_captured(pet_data, level)` hiện tự roll rarity/trait, nhân stat, append party, thưởng EXP/quest và không trả kết quả ownership.
- `WildCreature.capture_succeeded` hiện gọi Player rồi despawn bất kể roster commit có thành công hay không.
- `swap_active_pet` hủy/tạo lại companion từ dictionary; chưa có persistent pet instance ID.
- Không có party capacity contract. Không tự thêm giới hạn trong U1.7c.
- U1.7b giữ inventory bằng legacy dictionary với stable adapter; không tạo backing store mới.
