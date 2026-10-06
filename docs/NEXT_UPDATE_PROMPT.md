# Prompt cho model tiếp theo — U1.12j ranch state audit

Tiếp tục bằng đúng một package U1.12j: audit và thêm typed persistence state cho riêng `building.ranch`, phân biệt persistent food/production/assignment identity với runtime animal Node presentation. Không gộp crop/health/altar/turret, không đổi economy/timing rule và không serialize Node/Callable hoặc localized pet name. Chứng minh save/load không duplicate production/assignment, invalid identity/progress fail trước mutation, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
