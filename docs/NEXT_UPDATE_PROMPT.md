# Prompt cho model tiếp theo — U1.12n chest durability

Tiếp tục bằng đúng một package U1.12n: audit và thêm typed durability persistence cho riêng `building.chest`, mở rộng state hiện có mà không gộp health của subtype khác hoặc resource depletion. Không đổi max health, damage rule, inventory capacity/economy và không serialize Node/scene path. Chứng minh inventory cùng health round-trip chính xác, health ngoài miền fail trước mutation, load không phát destruction/reward side effect, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
