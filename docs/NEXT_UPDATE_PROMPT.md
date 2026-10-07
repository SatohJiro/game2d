# Prompt cho model tiếp theo — U1.12p cooking-pot durability

Tiếp tục bằng đúng một package U1.12p: audit và thêm typed durability persistence cho riêng `building.cooking_pot`, mở rộng cooking state hiện có mà không gộp health của subtype khác hoặc resource depletion. Không đổi max health, damage rule, recipe timer/economy và không serialize Node/scene path. Chứng minh recipe/progress cùng health round-trip chính xác, health ngoài miền fail trước mutation, load không phát destruction/reward/cooking side effect, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
