# Prompt cho model tiếp theo — U1.12aa world-boss actor audit

Tiếp tục bằng đúng một package U1.12aa: audit và thiết kế typed persistence tối thiểu cho world boss được `main.gd` spawn (khác altar boss). Xác định stable instance/lifecycle identity trước khi code; persist HP/position chỉ nếu ownership và defeat callback cho phép restore không reward lặp. Không serialize Node, scene path, banner hoặc RNG. Nếu lifecycle chưa đủ an toàn, chỉ tạo contract/pure state + regression và ghi blocker, không spawn actor giả. Chạy full gate + leak-aware log scan và cập nhật docs.
