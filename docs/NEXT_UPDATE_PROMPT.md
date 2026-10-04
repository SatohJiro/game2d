# Prompt triển khai package U1.4b

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, `docs/roadmap/U1_4_INVENTORY_PLAN.md`, `docs/architecture/INVENTORY_TRANSACTIONS.md`, `INVENTORY_MIGRATION.md`, `DOMAIN_DEFINITIONS.md` và module/gameplay docs. Chạy baseline gate trước khi sửa.

U1.4a đã VERIFIED: pure transaction trên một legacy backing dictionary, Player stable add/read/remove, rejected pickup retention. Capacity hiện explicit `UNLIMITED`; chest còn direct mutation.

Thực hiện U1.4b:

1. Chọn finite slot policy: slot usage = tổng `ceil(count/max_stack)`; max stack lấy từ injected item catalog/lookup, không load resource trong domain service.
2. Bổ sung capacity dependency/policy sao cho test có thể inject max-stack deterministic. Missing definition phải fail closed.
3. Mở legacy mapping chỉ cho typed item thực sự được chest migrate: wood, pal ore, berry trước; các key chest chưa có definition giữ legacy path hoặc nằm ngoài batch.
4. Migrate `BuildingChest` deposit/withdraw cho mapped items qua atomic transaction. Không sửa Player/chest dictionary trực tiếp trong path đã migrate.
5. Batch deposit phải plan toàn bộ trước commit hoặc ghi rõ partial policy. Ưu tiên all-or-nothing để UI có kết quả rõ; failure không mất/duplicate item.
6. Regression: exact max stack, mở stack hiện có, hết slot, missing definition, successful transfer conservation, source insufficient và target capacity rollback.
7. Notification/audio/HUD chỉ sau commit. Giữ consumer crafting/farm khác legacy.

Kết thúc bằng full gate, docs/checkpoint, commit branch package và fast-forward main. Ghi capacity formula, chest item scope, consumer còn legacy, save/asset impact, rollback và bước đầu U1.5.
