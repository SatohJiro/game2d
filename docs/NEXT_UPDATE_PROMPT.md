# Prompt cho model tiếp theo — U1.10d explicit pet commands

Tiếp tục bằng đúng một package nhỏ U1.10d: mở stable explicit commands cho auto-work, combat-assist và follow-protect trên `PetCommandPolicy`; giữ `cycle_stance` làm compatibility input. Khóa idempotent/no-change, invalid target và actor apply bằng regression. Chưa mở target selection, job reservation, command wheel, save schema hoặc UI redesign. Chạy focused regression, full gate, leak-aware log scan và cập nhật contract/checkpoint.
