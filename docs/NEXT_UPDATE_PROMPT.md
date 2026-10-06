# Prompt cho model tiếp theo — U1.9t remaining creature drops

Tiếp tục bằng đúng một package nhỏ U1.9t: audit Slime/Mushroom/Beast/Dragon defeat drops và migrate chúng sang deterministic `CreatureDropResult` + atomic commit theo stable item ID. Giữ quantity, elite/alpha bonus, capture/duplicate guards và presentation. Không đổi asset/save. Chạy focused regression, full gate, leak-aware log scan và cập nhật contract/checkpoint.
