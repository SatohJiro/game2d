# Prompt cho model tiếp theo — U1.12h cooking pot processing state

Tiếp tục bằng đúng một package U1.12h: thêm typed persistence state cho riêng `building.cooking_pot`, dùng stable recipe identity và giữ timer/trạng thái mẻ đang nấu cần thiết để resume chính xác. Không gộp compost/ranch/crop/health, không đổi recipe/economy/timing rule và không serialize Dictionary recipe runtime, Node hoặc Callable. Chứng minh save/load giữa mẻ không duplicate/mất nguyên liệu hay output, invalid recipe/progress fail trước mutation, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
