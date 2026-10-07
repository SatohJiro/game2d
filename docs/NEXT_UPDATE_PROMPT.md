# Prompt cho model tiếp theo — U1.12q ranch durability

Tiếp tục bằng đúng một package U1.12q: thêm typed durability persistence cho riêng `building.ranch`, mở rộng ranch state hiện có mà không gộp health subtype khác hoặc resource depletion. Giữ max health 350, damage rule, assignment/production economy và không serialize animal Node/scene path. Chứng minh assignments/food/progress cùng health round-trip chính xác, health ngoài miền fail trước mutation, load không phát destruction/reward/production side effect, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
