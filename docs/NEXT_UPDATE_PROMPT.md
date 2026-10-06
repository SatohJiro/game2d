# Prompt cho model tiếp theo — U1.12i compost processing state

Tiếp tục bằng đúng một package U1.12i: thêm typed persistence state cho riêng `building.compost_bin`, giữ organic material, fertilizer output và timer của mẻ đang xử lý. Không gộp ranch/crop/health, không đổi economy/timing rule và không serialize Node/Callable. Chứng minh save/load giữa mẻ không duplicate/mất input hoặc output, invalid count/progress fail trước mutation, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
