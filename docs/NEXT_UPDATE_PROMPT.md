# Prompt cho model tiếp theo — U1.12g furnace processing state

Tiếp tục bằng đúng một package U1.12g: thêm typed persistence state cho riêng `building.furnace` trên `BuildingPlacementRecord`, gồm committed input/output, timer và trạng thái chạy cần thiết để resume chính xác. Không gộp cooking pot/compost/ranch/crop/health, không đổi recipe/economy/timing rule và không serialize Node/Callable. Chứng minh save/load giữa mẻ luyện không duplicate/mất input hoặc output, payload invalid fail trước mutation, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
