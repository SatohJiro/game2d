# Prompt cho model tiếp theo — U1.12w world clock owner

Tiếp tục bằng đúng một package U1.12w: nối `main.gd` làm owner thật của `world.clock_seconds` qua explicit save/load boundary hiện có. Không để save module tìm scene bằng path hoặc mutate Main ngầm; world owner truyền clock khi save và chỉ commit clock sau load success. Giữ day duration/raid/boss/spawn rules hiện tại, chứng minh round-trip clock và failed load không đổi runtime clock; không mở autosave/UI hoặc encounter persistence. Chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
