# Prompt cho model tiếp theo — U3.1 theme/tokens + HUD ViewModel

U2 đã xong (world rộng: chunk identity, admission, persistent delta, spawn director, discovery/fast-travel/minimap, static content). Bắt đầu U3 UI/UX với package U3.1: theme/tokens tập trung + HUD ViewModel.

1. Tạo `ui/theme/paloria_theme.tres` (hoặc theme resource tương đương): palette, font size scale, corner radius, padding tokens dùng chung; thay style inline rải rác trong `hud.tscn`/`minimap.tscn` bằng theme overrides trỏ về tokens (không đổi layout).
2. Tạo `HUDViewModel` (RefCounted): snapshot read-only từ player state (HP/SP/hunger/thirst, level/exp, spheres count, pet card, quest panel) — `hud.gd` chỉ render ViewModel và phát intent, không đọc trực tiếp player node trong `_process`.
3. Giữ nguyên tắc UI: intent → coordinator → ViewModel/snapshot; modal focus/pause policy không đổi; hỗ trợ UI scale và reduced motion đã có.
4. Regression headless: ViewModel mapping đúng giá trị player, theme tokens resolve đủ, HUD render không crash khi ViewModel rỗng, Main integration (damage player → ViewModel update → HUD refresh).
5. Chạy focused checks rồi một full gate cuối + strict scan; cập nhật ui/module/gameplay/roadmap/checkpoint.
