# Prompt triển khai package U1.7b

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, INDEX/CHECKPOINT/roadmap, DATA_CONTRACTS, INVENTORY_TRANSACTIONS, CAPTURE_CONTRACT và G03/G05. Chạy full baseline trước khi sửa.

U1.7a deterministic capture result đã VERIFIED. Chỉ thực hiện U1.7b sphere inventory/spawn transaction:

1. Audit Player sphere selection/consume, recipes, LegacyItemAdapter, ItemDefinition registry, Sphere fields/visual và missed-sphere DroppedItem path.
2. Chuẩn hóa stable IDs `item.pal_sphere.basic`, `item.pal_sphere.mega`, `item.pal_sphere.giga`. Bổ sung typed definitions/mapping cần thiết, không tạo backing inventory thứ hai.
3. Tạo pure sphere selection/result từ available counts + priority/multiplier. Không dùng localized name làm identity.
4. Player flow phải: select/validate → instantiate/configure candidate → atomic inventory remove → add/launch → notify. Failure trước commit không trừ item; failure sau commit phải có rollback rõ hoặc không thể xảy ra theo invariant đã kiểm tra.
5. Sphere mang stable item ID; display/texture là adapter. Missed sphere tạo DroppedItem với stable ID và chỉ dùng legacy name qua adapter.
6. Giữ CaptureRequest/Result và roster/trait/despawn của U1.7a nguyên vẹn. Không làm PetInstance/save/UI redesign trong package này.
7. Regression: no sphere, priority giga>mega>basic, multiplier mapping, exact decrement một, cooldown/build rejection không trừ, unknown ID fail closed, missed drop stable ID, rejected pickup stays, main-scene Player/Sphere adapter.
8. Cập nhật content/data/inventory/capture docs, G03/G05, checkpoint/roadmap. Prompt kế tiếp U1.7c phải tách roster ownership/trait RNG/commit.

Kết thúc full gate, log sạch, commit branch riêng và fast-forward `main`. Ghi asset/save/data migration, compatibility, manual projectile test và rollback.
