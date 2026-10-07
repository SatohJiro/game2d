# Prompt cho model tiếp theo — U1.12ab world-boss ownership

Tiếp tục bằng đúng một package U1.12ab: cho Main sở hữu duy nhất world-boss actor `boss.world_dragon_1` và nhận lifecycle/defeat signal từ Creature trước khi actor free. Phân biệt active với defeated bằng `WorldBossState`; spawn trùng phải no-op/fail closed. Chưa nối Save v1, chưa restore actor và không đổi reward/drop. Regression phải chứng minh đúng một actor, callback chỉ commit đúng world boss và actor thường/altar boss không làm đổi state. Chạy full gate + leak-aware log scan và cập nhật docs.
