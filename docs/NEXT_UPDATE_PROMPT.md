# Prompt cho model tiếp theo — U1.12z ambient spawn timer

Tiếp tục bằng đúng một package U1.12z: persist riêng ambient `spawn_timer` trong typed world-cycle state. Giữ interval 4 giây và initial 3 giây; không serialize creature Node, spawn offset, species roll hoặc RNG. Chứng minh timer round-trip, invalid value fail trước mutation, load không tự spawn creature và failed load giữ runtime. Không mở creature roster/world chunk persistence. Chạy full gate + leak-aware log scan và cập nhật docs.
