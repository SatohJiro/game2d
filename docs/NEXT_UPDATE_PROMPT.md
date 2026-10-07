# Prompt cho model tiếp theo — U1.12y boss timer persistence

Tiếp tục bằng đúng một package U1.12y: persist riêng pre-spawn boss timer/guard trong typed world-cycle state. Không serialize boss Node, species presentation, banner hoặc RNG; nếu boss đã spawned thì chỉ lưu guard, chưa persist actor HP ở package này. Chứng minh timer/guard round-trip, invalid state fail trước mutation, load không tự spawn boss và failed load giữ runtime; giữ ambient creature spawn timer ngoài scope. Chạy full gate + leak-aware log scan và cập nhật docs.
