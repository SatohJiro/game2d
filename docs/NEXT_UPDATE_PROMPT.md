# Prompt cho model tiếp theo — U1.12l altar state audit

Tiếp tục bằng đúng một package U1.12l: audit và thêm typed persistence state cho riêng `building.altar`, phân biệt boss lifecycle state bền vững với runtime boss Node/presentation. Không gộp health/turret/resource depletion, không đổi summon cost/reward/combat rule và không serialize Node/Callable. Chứng minh save/load không duplicate boss hoặc reward, invalid lifecycle state fail trước mutation, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
