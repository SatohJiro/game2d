# Prompt cho model tiếp theo — U1.12b inventory identity closure

Tiếp tục bằng đúng một package U1.12b: tạo manifest/validator cho mọi localized inventory key mà producer/consumer runtime đang dùng; admit stable `item.*` definitions và mapping hai chiều cho các key reachable còn thiếu; chứng minh Player snapshot không còn `UNMAPPED_ITEM` sau farming/crafting/cooking/ranch output groups. Không migrate legacy backing dictionary, không đổi economy và không mở rộng world/base save DTO. Đọc `PERSISTENCE_COVERAGE_AUDIT.md`, chạy full gate, leak-aware log scan và cập nhật data/save/checkpoint docs.
