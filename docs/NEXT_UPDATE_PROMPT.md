# Prompt triển khai package U1.6a

Làm việc tại D:\desktop\VS_WorkSpace\game2d. Đọc AGENTS.md, docs/INDEX.md, docs/CHECKPOINT.md, roadmap, MODULES và G01/G02/G15. Audit toàn bộ hunger, thirst, temperature, stamina và food buff read/write trong player.gd trước khi sửa.

U1.1–U1.5 đã VERIFIED. U1.6 phải chia nhỏ vì player.gd chứa input, locomotion, combat, needs, crafting và building.

Thực hiện U1.6a needs boundary:

1. Ghi rõ owner hiện tại, timer, clamp, pause behavior, HUD fields và direct writer.
2. Tạo pure PlayerNeedsState hoặc tương đương cho hunger/thirst/temperature và timed food buff; không truy cập Input, SceneTree, HUD, audio.
3. API tick nhận delta/context và trả snapshot/events; mọi value clamp [0,max]. Pause phải do coordinator không gọi tick hoặc context policy rõ.
4. Migrate calculation trong Player, giữ public fields/adapter nếu consumer cũ cần. HUD chỉ render snapshot.
5. Không tách locomotion, build placement, crafting hoặc progression trong cùng package.
6. Regression: zero/large delta clamp, pause/no tick, buff expiry một lần, deterministic same state/input và adapter main scene.
7. Đo line/responsibility thay đổi thật; không tuyên bố Player hoàn tất.

Kết thúc full gate, docs/checkpoint, commit/fast-forward. Ghi compatibility, save/asset impact, direct writer còn lại và scope U1.6b locomotion/input.
