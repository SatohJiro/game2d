# Prompt cho model tiếp theo — U1.12m turret state

Tiếp tục bằng đúng một package U1.12m: audit và thêm typed persistence state cho riêng `building.turret`, chỉ giữ mutable combat state thật sự cần thiết qua save/load. Không gộp health/resource depletion, không đổi damage/range/fire-rate/targeting rule và không serialize target Node/Callable. Chứng minh save/load không tạo phát bắn hoặc giữ stale target, invalid cooldown fail trước mutation, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
