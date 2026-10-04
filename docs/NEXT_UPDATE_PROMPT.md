# Prompt triển khai package U1.6c

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, roadmap, MODULES, hai contract Player và G01/G15. Chạy `tools/check_project.ps1` trước khi sửa.

U1.1–U1.6b đã VERIFIED. Chỉ thực hiện U1.6c action input router:

1. Audit toàn bộ nhánh trong `Player._input` và held attack polling: physical key/mouse, modal/build guard, handler, side effect và consume/return behavior.
2. Tạo typed action intent với stable IDs cho attack, roll, interact, capture throw, craft/stat modal, build/cancel/place, pet swap/command/skill, food và elixir. Display text/key label không được làm identity.
3. Input adapter có thể phụ thuộc `InputEvent`; mapping/result/router không được mutate inventory, HP, world Node hoặc UI trực tiếp.
4. Player coordinator nhận intent rồi gọi handler cũ. Giữ nguyên key mapping, modal guard, build-mode precedence và held attack cadence; chưa chuyển sang InputMap nếu không thể giữ tương thích.
5. Không migrate capture probability, building placement, recipes, progression hoặc HUD presentation trong package này.
6. Regression: mỗi key/mouse map đúng intent; echo/release bị bỏ; modal/build guard; pet slot payload; unknown event no-op; deterministic mapping; main-scene adapter.
7. Cập nhật G01/G15, module contract, checkpoint và roadmap. Ghi danh sách handler/domain debt còn lại.
8. Kết thúc bằng full gate, commit branch riêng và fast-forward `main`. Sau đó prompt kế tiếp phải là U1.7a capture request/result pure trước khi đổi roster/despawn.

Ghi rõ save/data/asset impact, compatibility, manual test còn thiếu và rollback.
