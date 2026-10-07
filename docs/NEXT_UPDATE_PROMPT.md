# Prompt cho model tiếp theo — U1.12t workbench durability

Tiếp tục bằng đúng một package U1.12t: thêm typed durability persistence cho riêng `building.workbench`, subtype hiện chưa có mutable placement state. Giữ max health 200, damage/crafting rule và không serialize Node, Callable hoặc scene path. Chứng minh health round-trip chính xác, health ngoài miền fail trước mutation, load không phát destruction/crafting side effect, giữ compatibility với record state rỗng cũ, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
