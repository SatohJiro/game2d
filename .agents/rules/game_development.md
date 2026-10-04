# QUY TẮC & TIÊU CHUẨN PHÁT TRIỂN GAME (AI AGENT GAME DEV RULES)

Tài liệu này định hình toàn bộ nguyên tắc thiết kế, kiến trúc mã nguồn, tối ưu hóa hiệu năng và trải nghiệm game (Game Feel) khi AI Agent làm việc trên dự án game (đặc biệt với Godot Engine 4.x và game 2D).

---

## 1. NGUYÊN TẮC THIẾT KẾ KIẾN TRÚC (ARCHITECTURE PRINCIPLES)

### 1.1. "Call Down, Signal Up" (Nguyên tắc vàng của Godot)
- **Node cha gọi Node con**: Node cha có thể gọi trực tiếp hàm của Node con vì nó biết chắc con tồn tại.
- **Node con báo cho Node cha qua Signal**: Node con **KHÔNG ĐƯỢC** gọi ngược lên cha bằng `get_parent().do_something()` cứng nhắc. Thay vào đó, định nghĩa `signal` (ví dụ `signal health_depleted`, `signal captured(data)`) và phát tín hiệu `emit()`.

### 1.2. Độc lập & Tự chứa (Self-Contained Scenes)
- Mỗi Scene (`Player.tscn`, `Creature.tscn`, `Pet.tscn`, `ResourceNode.tscn`) phải hoạt động độc lập được khi nhấn **F6** (Run Current Scene) mà không phụ thuộc vào việc Scene cha phải tồn tại.
- Kiểm tra tính hợp lệ trước khi truy xuất: Luôn dùng `is_instance_valid(target)`, `is_inside_tree()`, hoặc `has_method("...")`.

### 1.3. Phân tách Dữ liệu & Logic (Data-Driven Architecture)
- Tách rời dữ liệu chỉ số (chủng loài, máu cơ bản, tốc độ, bảng tỉ lệ rơi đồ) thành `Dictionary`, `Resource` (`.tres`), hoặc hằng số có cấu trúc.
- Tránh hardcode chỉ số rải rác trong các nhánh `if/else`.

### 1.4. Tách biệt UI / HUD hoàn toàn khỏi Gameplay
- UI chỉ phản chiếu trạng thái (`View`) bằng cách lắng nghe sự kiện hoặc nhận dữ liệu thông qua hàm cập nhật tập trung (`update_player_stats`, `update_inventory`).
- Nghiêm cấm đặt logic chiến đấu, trừ máu hay tính toán kinh nghiệm bên trong kịch bản UI.

---

## 2. NGUYÊN TẮC CẢM GIÁC GAME & TRẢI NGHIỆM (GAME FEEL & JUICE)

Trò chơi hay không chỉ ở cơ chế, mà ở **độ phản hồi (Feedback) và cảm giác thỏa mãn (Juice)** khi người chơi thao tác:

1. **Hit Feedback (Phản hồi va chạm)**:
   - Khi đánh trúng quái: Quái phải **chớp trắng/đỏ (Hit Flash)** ngay lập tức bằng `Tween` đổi `modulate`.
   - Có độ đẩy lùi (Knockback) nhẹ dựa trên hướng đánh.
   - Hiện **Số sát thương bay lên (Floating Damage Numbers)** với màu sắc trực quan (Đỏ: sát thương, Xanh lá: hồi máu, Xanh dương: EXP, Vàng: chí mạng).
2. **Squash & Stretch (Co giãn hoạt họa)**:
   - Khi nhảy, tiếp đất, chém kiếm hoặc ném bóng: Co giãn nhẹ `scale` (ví dụ từ `(1.0, 1.0)` sang `(1.2, 0.8)` rồi đàn hồi về) để vật thể sống động như phim hoạt hình.
3. **Screen Shake (Rung lắc màn hình có kiểm soát)**:
   - Rung nhẹ (2-4px) khi người chơi bị đánh đau hoặc khi tung đòn kết liễu quái vật / Boss.
4. **Máy trạng thái hữu hạn (FSM - Finite State Machine)**:
   - Nhân vật và AI quái vật/pet phải dùng Enum trạng thái (`IDLE`, `WANDER`, `CHASE`, `ATTACK`, `STUN`, `CAPTURING`).
   - Tránh dùng chuỗi cờ boolean lồng nhau khó bảo trì.

---

## 3. NGUYÊN TẮC TỐI ƯU HÓA HIỆU NĂNG (PERFORMANCE OPTIMIZATION)

1. **Phân biệt Physics vs Idle Frame**:
   - `_physics_process(delta)`: Chỉ dùng cho di chuyển vật lý (`move_and_slide()`), va chạm, Raycast và logic game đồng bộ thời gian thực.
   - `_process(delta)`: Dùng cho xoay góc nhìn, hiệu ứng hoạt họa visual, UI và animation nhấp nháy.
2. **Phân tầng Va chạm (Collision Layers & Masks)**:
   - Phải thiết lập Layer số cụ thể:
     - `Layer 1`: Người chơi (Player)
     - `Layer 2`: Quái vật hoang dã & Pet (Creatures)
     - `Layer 3`: Môi trường & Chướng ngại vật (World / Obstacles)
     - `Layer 4`: Đạn đạo & Cầu thu phục (Projectiles / Spheres)
   - Không bật mask quét toàn bộ layer (tiêu tốn CPU vật lý vô ích).
3. **Dọn dẹp bộ nhớ (Node Lifecycle)**:
   - Mọi thực thể sinh ra tạm thời (Floating Text, đòn chém, bóng thu phục, hiệu ứng nổ) phải tự động gọi `queue_free()` sau khi hết thời gian tồn tại.
4. **Pixel Art Rendering**:
   - Luôn đặt `texture_filter = nearest` trong cài đặt dự án hoặc từng sprite để hình ảnh sắc nét, không bị mờ nhòe bilinear.
   - Dùng chế độ hiển thị `canvas_items` với `keep` aspect ratio để tương thích mọi kích thước màn hình.

---

## 4. QUY TRÌNH PHÁT TRIỂN & KIỂM TRA (AI AGENT WORKFLOW)

1. **Triển khai gia tăng (Incremental Delivery)**:
   - Xây dựng theo từng lát cắt dọc hoàn chỉnh (Vertical Slice): Core Movement ➔ Combat ➔ Capture ➔ Farming ➔ Automation ➔ Polish.
2. **Tự động kiểm tra tính đúng đắn trước khi bàn giao**:
   - Dùng lệnh CLI headless của Godot (`godot --headless --check-only` hoặc chạy giả lập) để quét lỗi cú pháp, lỗi thiếu Node path, lỗi circular dependency trước khi thông báo cho người dùng.
3. **Tương thích & Phòng vệ**:
   - Luôn bọc các phương thức gọi ngoài bằng kiểm tra kiểu hoặc `has_method()`.
