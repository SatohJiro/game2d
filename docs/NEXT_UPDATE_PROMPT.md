# Prompt cho model tiếp theo — U1.12o furnace durability

Tiếp tục bằng đúng một package U1.12o: audit và thêm typed durability persistence cho riêng `building.furnace`, mở rộng processing state hiện có mà không gộp health của subtype khác hoặc resource depletion. Không đổi max health, damage rule, smelting timer/economy và không serialize Node/scene path. Chứng minh input/output/progress cùng health round-trip chính xác, health ngoài miền fail trước mutation, load không phát destruction/reward/smelting side effect, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
