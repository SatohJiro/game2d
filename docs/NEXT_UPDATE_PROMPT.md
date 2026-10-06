# Prompt cho model tiếp theo — U1.12f building subtype state audit

Tiếp tục bằng đúng một package U1.12f: audit mutable state theo từng building subtype và chọn đúng một vertical slice ưu tiên (chest hoặc một processing station) để thêm typed state DTO trên `BuildingPlacementRecord`. Không gom toàn bộ subtype trong một package, không đổi economy/timer rule và không serialize Node/Callable. Chứng minh save/load giữa tiến trình không duplicate/mất committed item, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
