# Prompt cho model tiếp theo — U1.12ae raid actor audit

Tiếp tục bằng đúng một package U1.12ae: audit ba night-raid actors và thiết kế typed persistence tối thiểu trước khi nối Save v1. Xác định stable encounter/instance identity, active/cleared semantics, HP/position và quan hệ với `raid_triggered_this_cycle`; không serialize Node, target, species RNG hoặc scene path. Nếu ownership/removal lifecycle chưa đủ an toàn, chỉ tạo pure contract + regression và ghi blocker như U1.12aa. Không spawn actor giả khi load. Chạy full gate + leak-aware log scan và cập nhật docs.
