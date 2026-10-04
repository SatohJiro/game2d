# Paloria 3.0 — chỉ mục tài liệu

Tài liệu này là điểm vào bắt buộc cho người và AI agent. Trạng thái thực thi gần nhất nằm trong `CHECKPOINT.md`; roadmap không được dùng thay cho bằng chứng kiểm thử.

## Thứ tự đọc

1. `AGENTS.md`: quy tắc bắt buộc và lệnh kiểm tra.
2. `docs/CHECKPOINT.md`: work package gần nhất, thay đổi thật và phần còn lại.
3. `docs/roadmap/IMPLEMENTATION_PHASES.md`: thứ tự package và gate.
4. `docs/architecture/MODULES.md`: ownership, contract và ranh giới module.
5. `docs/gameplay/FEATURES.md`: luật chơi, invariant và acceptance criteria.
6. `docs/ASSET_PLAN.md` cùng `docs/assets/INVENTORY.md`: asset, license và quarantine.
7. `docs/process/DOCUMENTATION_STANDARD.md`: tài liệu phải cập nhật khi sửa code/data/content.
8. `docs/process/VERSION_CONTROL.md`: branch, commit và phục hồi snapshot an toàn.

## Nguồn sự thật

| Chủ đề | Tài liệu chính | Khi nào phải cập nhật |
|---|---|---|
| Tiến độ hiện tại | `CHECKPOINT.md` | Sau mỗi work package |
| Phase, thứ tự, gate | `roadmap/IMPLEMENTATION_PHASES.md` | Khi scope hoặc dependency thay đổi |
| Kiến trúc và API module | `architecture/MODULES.md` | Khi tạo module, đổi ownership, signal hoặc data flow |
| Gameplay và cân bằng | `gameplay/FEATURES.md` | Khi luật chơi, input, reward hoặc failure state đổi |
| Asset | `ASSET_PLAN.md`, `assets/*` | Khi thêm, thay, xóa, đổi license hoặc derivative |
| Quyết định dài hạn | `decisions/ADR-*.md` | Trước thay đổi khó đảo ngược |
| Cách chạy | `README.md` | Khi toolchain, input hoặc launch flow đổi |

## Trạng thái tổng quan ngày 2026-10-04

| Hạng mục | Trạng thái | Bằng chứng / blocker |
|---|---|---|
| U0.1 baseline | Hoàn tất | Godot editor-load và main-scene smoke xanh |
| U0.2 asset inventory | Hoàn tất | Manifest/hash gate xanh; 166/166 asset chưa xác minh provenance |
| Git snapshot | Hoàn tất | Branch `main`, root commit `2c243e1`, tag `baseline-u0.3` |
| Kiến trúc data-driven | Chưa làm | Dictionary và logic còn tập trung trong god scripts |
| Save/load | Chưa có | Chưa có schema/version/migration |
| World streaming | Chưa có | `main.tscn` vẫn là world tĩnh |
| UI system | Prototype | HUD lớn, style inline, chưa có Theme/accessibility settings |
| Asset admission mới | Bị chặn | `game-dev` CLI chưa có trong PATH |

## Quy ước trạng thái

- `PLANNED`: mới có đặc tả.
- `IMPLEMENTING`: code/data đang thay đổi, gate chưa đạt.
- `PLAYABLE`: chạy được trong vertical slice nhưng chưa đủ chất lượng phát hành.
- `VERIFIED`: acceptance criteria và test đã có bằng chứng.
- `BLOCKED`: có điều kiện ngoài package ngăn tiến độ, phải ghi rõ trong checkpoint.
- `QUARANTINE`: asset có thể giữ baseline local nhưng không đủ điều kiện phân phối.
