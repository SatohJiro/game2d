# Prompt cho model tiếp theo — U1.11f runtime save coordinator

Tiếp tục bằng đúng một package nhỏ U1.11f: tạo coordinator explicit save/load kết nối SnapshotAdapter → Repository và Repository → MigrationRegistry → ApplyAdapter, với typed result và world-clock handoff. Failure ở bất kỳ stage nào không apply partial runtime; recovery source phải được phản ánh. Chưa autosave, pause policy hoặc UI slot. Chạy scene-level round-trip regression trong path tạm, full gate, leak-aware log scan và cập nhật contract/checkpoint.
