# Prompt triển khai package U1.3

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, `docs/roadmap/IMPLEMENTATION_PHASES.md`, `docs/architecture/DATA_CONTRACTS.md`, `docs/architecture/INVENTORY_MIGRATION.md`, `docs/architecture/MODULES.md` và `docs/gameplay/FEATURES.md`. Kiểm tra code/Git thực tế trước khi sửa; không suy trạng thái chỉ từ tài liệu.

U0.1–U0.4, U1.1 và U1.2 đã được kiểm chứng. Restore tag là `baseline-u0.3`. U1.2 đã migrate riêng luồng wood pickup qua `item.wood`, nhưng `Player.inventory["Gỗ"]` vẫn là nguồn sự thật duy nhất để giữ tương thích. Không xóa adapter hoặc đổi toàn bộ inventory trong U1.3.

Thực hiện đúng một work package U1.3 dài 0,5–2 ngày:

1. Audit recipe/workbench/crop prototype hiện có và ghi rõ ba canary được chọn trước khi code.
2. Tạo `RecipeDefinition`, `BuildingDefinition`, `CropDefinition` typed, mỗi subtype tự validate domain, required field, positive quantity/time và tham chiếu content.
3. Tạo tối thiểu một `.tres` cho mỗi subtype. Dùng stable ID; localization key tách khỏi identity.
4. Mở rộng `ContentRegistry`/validator để phát hiện missing cross-reference và input/output không hợp lệ theo thứ tự deterministic.
5. Chỉ nối tối đa một runtime read boundary nếu có thể giữ các consumer legacy bằng adapter và package không chạm quá ba module. Không rewrite crafting, building, farming và inventory cùng lúc.
6. Viết regression headless cho valid canary, invalid domain/value, duplicate và missing reference; thêm vào `tools/check_project.ps1` nếu cần.

Acceptance bắt buộc:

- Existing editor-load, content validator, item migration validator và 120-frame main smoke vẫn xanh, log không có `SCRIPT ERROR`, `ERROR`, missing resource hoặc invalid node path.
- Definition không dùng tên tiếng Việt, scene path hoặc asset path làm identity.
- Không tạo inventory store thứ hai; save/data impact và compatibility được ghi rõ.
- Không thêm asset ngoài. Nếu asset cần thiết chưa VERIFIED, giữ reference hiện hữu và ghi quarantine; `game-dev` CLI hiện thiếu nên không tải loose file để lách gate.
- Đồng bộ `DATA_CONTRACTS`, `MODULES`, `FEATURES`, roadmap, `CHECKPOINT` và prompt package tiếp theo theo `DOCUMENTATION_STANDARD.md`.

Kết thúc bằng `tools/check_project.ps1`, `git diff --check`, commit trên branch package rồi fast-forward vào `main`. Ghi commit, lệnh/log, file thay đổi, phần chưa kiểm chứng, rollback và bước đầu của U1.4 trong checkpoint.
