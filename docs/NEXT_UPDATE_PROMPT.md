# Prompt triển khai package U1.4

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc theo thứ tự: `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, `docs/roadmap/U1_4_INVENTORY_PLAN.md`, `docs/architecture/INVENTORY_MIGRATION.md`, `docs/architecture/DOMAIN_DEFINITIONS.md`, `docs/architecture/DATA_CONTRACTS.md`, `docs/architecture/MODULES.md` và G03/G10/G11 trong `docs/gameplay/FEATURES.md`. Kiểm tra Git/code thực tế và chạy baseline gate trước khi sửa.

U0.1–U0.4 và U1.1–U1.3 đã được kiểm chứng. U1.3 có 8 typed definitions và deterministic missing-reference validation, nhưng runtime recipe/building/crop vẫn dùng prototype. U1.2 chỉ map wood stable ID lên dictionary legacy. Không xóa compatibility adapter và không tạo stable dictionary song song.

Thực hiện một work package U1.4a dài 0,5–2 ngày:

1. Audit mọi direct mutation của `Player.inventory` và `BuildingChest.stored_items`; ghi owner và danh sách consumer còn legacy.
2. Thiết kế pure `InventoryTransaction` + result/status cho get/add/remove/transfer trên backing dictionary được inject. Service không truy cập SceneTree/HUD/audio và không giữ bản sao state.
3. Chọn capacity policy rõ ràng. Nếu max-stack/slot cần registry bootstrap làm package quá lớn, dùng explicit unlimited policy ở U1.4a và để finite capacity cho U1.4b; không giả vờ acceptance inventory-full đã đạt.
4. Mở rộng legacy mapping chỉ cho item có definition và consumer trong scope. Stable operation phải mutate chính legacy dictionary để giữ một nguồn sự thật.
5. Migrate Player/drop qua transaction boundary. Chỉ migrate chest trong cùng package nếu có regression atomic transfer và phạm vi vẫn nhỏ; nếu không, ghi U1.4b.
6. Regression bắt buộc: invalid ID/amount không mutate; insufficient remove không trừ dở; transfer thành công bảo toàn tổng; transfer thất bại rollback hai đầu; legacy read thấy stable mutation; pickup thất bại không despawn.
7. Notification HUD/quest/audio chỉ phát một lần sau commit thành công.

Không chuyển recipe/farm/building placement sang typed runtime trong package này. Không thêm asset. Không đổi save format. Không thêm feature vào `player.gd` ngoài adapter mỏng gọi domain transaction.

Kết thúc bằng `tools/check_project.ps1`, `git diff --check`, cập nhật module/data/gameplay/roadmap/checkpoint và commit trên branch package rồi fast-forward vào `main`. Checkpoint phải ghi capacity policy thật, consumer còn legacy, test/log, rollback, save/asset impact và scope U1.4b hoặc U1.5.
