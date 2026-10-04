# Prompt triển khai đợt update lớn

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md` và tài liệu module/feature liên quan trước. Kiểm tra code thực tế, không suy trạng thái chỉ từ tài liệu.

Luôn làm một work package nhỏ 0,5–2 ngày. U0.3 đã kiểm chứng và có tag `baseline-u0.3`; gói kế tiếp là U0.4 lập quarantine/replacement priority cho 166 asset. Chưa xóa hoặc di chuyển asset ở U0.4.

Sau U0, tách lần lượt data Resources và boundary nhỏ; không rewrite `player.gd`, `creature.gd`, HUD và world cùng lúc. Giữ vertical slice chơi được sau mỗi gói. Không thêm feature mới vào god scripts nếu boundary liên quan chưa được tách.

Asset ngoài phải theo `docs/ASSET_PLAN.md`: license/provenance/hash, staging/package, review style rồi mới admit. `game-dev` CLI hiện thiếu; không tải loose asset để bỏ qua gate. Không dùng Pokémon/Palworld sprite hoặc asset UNKNOWN cho bản phát hành.

Khi kết thúc mỗi gói, áp dụng `docs/process/DOCUMENTATION_STANDARD.md`: cập nhật module contract, gameplay rule, roadmap và checkpoint tương ứng. Ghi lệnh/log/kết quả thật, save/data breaking change, asset provenance, phần chưa kiểm chứng và bước đầu tiếp theo. Không tuyên bố milestone hoàn tất nếu gate chưa đạt.
