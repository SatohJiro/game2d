# Prompt cho model tiếp theo — U1.11d atomic save repository

Tiếp tục bằng đúng một package nhỏ U1.11d: tạo repository JSON cho Save v1 với temp-write, atomic replace, backup và typed result; read phải parse + validate trước khi trả snapshot, corrupt primary có recovery policy rõ. Chưa autosave, migration version hoặc UI slot. Chạy focused regression trong thư mục tạm cô lập, full gate, leak-aware log scan và cập nhật contract/checkpoint.
