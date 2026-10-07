# Prompt cho model tiếp theo — U1.12s turret structure durability

Tiếp tục bằng đúng một package U1.12s: thêm typed structure durability cho riêng `building.turret`, mở rộng cooldown state hiện có. Giữ max health 350, damage/range/fire-rate/targeting rule và không serialize target/projectile Node, Callable hoặc scene path. Chứng minh cooldown cùng health round-trip chính xác, health ngoài miền fail trước mutation, load không phát shot/destruction hoặc giữ stale target, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
