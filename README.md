# Paloria 2D - Phiêu Lưu Sinh Tồn, Thu Phục Pet & Nông Trại (Godot 4)

> Bắt đầu tại [chỉ mục tài liệu](docs/INDEX.md) · [kiến trúc/UI/world/gameplay](docs/MAJOR_UPDATE_PLAN.md) · [asset và license](docs/ASSET_PLAN.md) · [checkpoint hiện tại](docs/CHECKPOINT.md). Baseline U0.2 đã xanh trên Godot 4.7.2; đọc `AGENTS.md` trước khi tiếp tục phát triển.

Tựa game phiêu lưu 2D Top-Down lấy cảm hứng từ **Palworld**, **Pokemon** và **Stardew Valley** được xây dựng trên nền tảng **Godot Engine 4.7+**.

---

## 🎮 Cách chạy Game

1. **Chơi ngay (1 Click)**:
   * Nhấp đúp chuột vào file `run_game.bat`.
2. **Mở bằng Godot Editor**:
   * Mở Godot Engine -> Chọn **Import** -> Trỏ tới thư mục `game2d` -> Mở `project.godot`.
   * Nhấn **F5** để chạy game.
3. **Kiểm tra tự động**:
   * Chạy `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1` để load project và smoke-test main scene ở chế độ headless.

---

## 🕹️ Bảng Phím Điều Khiển

| Phím / Thao tác | Chức năng |
| :--- | :--- |
| **W, A, S, D** / Mũi tên | Di chuyển nhân vật 8 hướng |
| **Shift** | Giữ để chạy nhanh (tiêu hao Stamina) |
| **Chuột Trái / Space** | Chém kiếm theo hướng chuột / Chặt cây / Đập quặng |
| **Chuột Phải / Q** | Ném **Cầu Thu Phục (Pal Sphere)** về hướng chuột |
| **E** | Tương tác: Gieo hạt, kiểm tra cây trồng, thu hoạch |
| **R** | Ra lệnh cho Pet đổi chế độ: *Tự do Tấn công* <-> *Theo sát Bảo vệ* |
| **F** | Ăn quả mọng để hồi 30 Máu (HP) |
| **C** | Chế tạo nhanh 2 Cầu Thu Phục (cần 2 Gỗ, 3 Đá, 1 Quặng Pal) |

---

## 🐾 Hệ thống Gameplay Cốt Lõi

1. **Thu phục Pet (Pal Taming)**:
   * 3 chủng loài hoang dã: **Foxfire** (Hệ Lửa), **Pengu** (Hệ Nước), **Sproutling** (Hệ Cỏ).
   * Đánh quái yếu máu (< 40%) để nâng tỉ lệ bắt lên tới **85% - 95%**.
   * Cầu rung 3 nhịp trước khi phong ấn thành công.
2. **Pet đồng hành (Companion AI)**:
   * Đi theo chủ nhân, tự động tham chiến hỗ trợ khi chủ nhân bị tấn công hoặc ra lệnh.
   * Lên cấp, tăng máu, tăng sát thương độc lập.
3. **Khai thác & Chế tạo (Gathering & Crafting)**:
   * Cây rừng -> Gỗ + Hạt giống cây.
   * Mỏ đá -> Đá + Quặng Pal.
   * Chế tạo Cầu Thu Phục bất kỳ lúc nào khi đủ nguyên liệu.
4. **Nông trại (Farming)**:
   * Luống đất tại căn cứ: Gieo hạt -> Nảy mầm -> Cây non -> Quả chín -> Thu hoạch quả mọng.

---

## 📁 Cấu trúc Dự án
* `project.godot`: Tệp cấu hình dự án Godot 4.
* `scenes/`: Chứa các Scene (`main.tscn`, `player.tscn`, `creature.tscn`, `pet.tscn`, `resource_node.tscn`, `hud.tscn`, `sphere.tscn`, `slash_effect.tscn`, `floating_text.tscn`).
* `scripts/`: Chứa mã GDScript tương ứng điều khiển logic game.
* `run_game.bat`: Script khởi chạy game nhanh.
