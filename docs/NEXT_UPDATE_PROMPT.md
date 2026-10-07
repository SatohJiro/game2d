# Prompt cho model tiếp theo — U1.12k farm-plot state

Tiếp tục bằng đúng một package U1.12k: thêm typed persistence state cho riêng `building.farm_plot`, dùng stable crop identity và giữ stage/growth/moisture/water/fertilizer state cần thiết. Không gộp health/altar/turret/resource-node depletion, không đổi farming economy/timing rule và không serialize enum/localized text/Node. Chứng minh save/load giữa quá trình trồng không duplicate harvest hoặc reset progress, invalid crop/stage/progress fail trước mutation, chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
