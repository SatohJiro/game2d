# Prompt triển khai package U1.6b

Làm việc tại `D:\desktop\VS_WorkSpace\game2d`. Đọc `AGENTS.md`, `docs/INDEX.md`, `docs/CHECKPOINT.md`, roadmap, MODULES, `PLAYER_NEEDS_CONTRACT.md` và G01/G02. Chạy `tools/check_project.ps1` trước khi sửa.

U1.1–U1.6a đã VERIFIED. Chỉ thực hiện U1.6b input/locomotion boundary:

1. Audit mọi read/write của `stamina`, `max_stamina`, `is_sprinting`, `is_rolling`, `roll_timer`, `roll_direction`, `velocity`, invulnerability và movement input; ghi caller/owner/behavior hiện tại.
2. Tạo typed movement input snapshot/command. Input adapter có thể đọc Godot Input, nhưng pure locomotion calculation không truy cập Input, SceneTree, HUD, audio, animation hoặc CharacterBody2D.
3. Pure contract sở hữu stamina/sprint/roll timer và trả desired velocity/speed/state transition. Needs chỉ cung cấp multiplier qua API hiện có; không sao chép needs field vào locomotion store.
4. Player vẫn áp velocity, `move_and_slide`, collision và presentation. Giữ đúng roll i-frame; combat knockback phải có precedence rõ.
5. Giữ keyboard behavior qua adapter. Nếu thêm InputMap action, giữ fallback và cập nhật README/G01; gamepad/remap UI thuộc U3.
6. Không tách attack/capture/build/craft/progression, không đổi balance, animation hoặc HUD.
7. Regression: idle regen/clamp; sprint eligibility/drain; low stamina; roll start/cost/timer/i-frame/end; zero/large delta; deterministic repeat; needs multiplier; knockback precedence; main-scene adapter.
8. Đo responsibility/line count, cập nhật contract, G01, roadmap, checkpoint và prompt tiếp theo.

Kết thúc full gate, log sạch, commit branch riêng và fast-forward `main`. Ghi save/data/asset impact, compatibility, direct writer còn lại và rollback.
