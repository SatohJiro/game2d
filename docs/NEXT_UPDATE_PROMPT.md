# Prompt cho model tiếp theo — U1.9q Slime hop definition

Tiếp tục bằng đúng một package nhỏ U1.9q: migrate Slime hop tuning sang stable typed skill definition. Audit movement/tween/contact trước khi sửa; giữ visual, damage và lifecycle compatibility. Không migrate Beast charge, Dragon melee, drop execution, asset hoặc save. Chạy focused regression, full `tools/check_project.ps1`, leak-aware log scan và `git diff --check`; cập nhật contract/checkpoint và không tuyên bố hoàn tất U1.9 khi remaining writers chưa đạt gate.
