# Prompt cho model tiếp theo — U1.11e migration harness

Tiếp tục bằng đúng một package nhỏ U1.11e: tạo migration registry/result thuần để route tuần tự schema version cũ đến current, fail closed cho version tương lai, thiếu step, cycle hoặc invalid output. Vì chưa có save phát hành trước v1, không tạo migration dữ liệu giả; khóa no-op v1 và failure paths bằng regression. Chưa autosave, runtime coordinator hoặc UI slot. Chạy full gate, leak-aware log scan và cập nhật contract/checkpoint.
