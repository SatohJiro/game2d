# Kế hoạch asset và provenance

## Quyết định phong cách

Chọn pixel-art top-down nhất quán, target grid 32×32 cho gameplay. Có thể scale nguyên 2×/3× bằng nearest filter. Ưu tiên asset CC0 làm nền/UI/prompt; pet chính cần art gốc hoặc một pack animation đồng nhất, không lấy Pokémon/Palworld sprite.

## Candidate đã xác minh từ trang nguồn

| Gói | Mục đích | Thông số | License | Nguồn |
|---|---|---|---|---|
| Kenney Tiny Farm | terrain/crop/farm prototype | 130 file, tile 16×16 | CC0 | https://kenney.nl/assets/tiny-farm |
| Kenney UI Pack – Pixel Adventure | panel/button/progress/slider | 500 file | CC0 | https://kenney.nl/assets/ui-pack-pixel-adventure |
| Kenney Input Prompts Pixel | keyboard/mouse/gamepad prompts | 800 file, 16×16 | CC0 | https://kenney.nl/assets/input-prompts-pixel |
| Kenney Monster Builder Pack | concept/prototype creature parts | 170 file | CC0 | https://kenney.nl/assets/monster-builder-pack |
| Kenney Particle Pack | VFX source | 80 file, 512×512 | CC0 | https://kenney.nl/assets/particle-pack |
| OpenGameArt Animated Monsters | animation reference/enemy prototype | idle/walk/punch/hurt/fall | CC0 | https://opengameart.org/content/animated-monsters |

Tiny Farm 16×16 phải upscale 2× hoặc dùng như reference; không trộn trực tiếp với sprite 48/64 px nếu art bible chưa chốt. Monster Builder chủ yếu là modular static art, không tự giải quyết animation pet. Candidate không đồng nghĩa đã duyệt mỹ thuật hoặc đã nhập project.

## Quy trình bắt buộc

1. Tải ZIP vào staging ngoài `assets/game`, không copy loose file thẳng vào scene.
2. Ghi URL trang nguồn, URL download thực, ngày tải, tác giả, license/SPDX, SHA-256 ZIP.
3. Giải nén thư mục package riêng; giữ license/readme nguyên bản; tạo file manifest liệt kê hash.
4. Review kích thước, alpha, frame layout, palette và animation coverage. Chỉ chọn subset cần dùng.
5. Normalize sang grid/palette mà không ghi đè source; source ở `assets/vendor`, derivative ở `assets/game` kèm recipe/prompt.
6. Headless import, kiểm tra missing resource, rồi human visual review trong Godot.
7. Cập nhật credits dù CC0 không bắt buộc, vì cần provenance nội bộ.

## Trạng thái công cụ

`game-dev` CLI không có trong PATH ngày 2026-10-04. Theo workflow Game Development Studio, chưa được phép tuyên bố package/vendoring đã hoàn tất và không tải loose asset thay thế. Cần cài/configure CLI ngoài lượt này hoặc người dùng chọn quy trình asset thủ công có manifest tương đương. Hiện chưa có file candidate nào được tải vào project.

## Inventory hiện hữu

U0.2 đã ghi 166 asset nguồn vào `docs/assets/asset_manifest.csv` và bản machine-readable JSON. Có 69 file được code/scene tham chiếu, 97 file chưa được tham chiếu và 3 nhóm trùng hash (18 file). Ba PNG thử nghiệm ở root được xếp category `_root`; toàn bộ 166 file đang `QUARANTINE/UNKNOWN` vì chưa có bằng chứng nguồn và quyền phân phối.

- Chạy `tools/generate_asset_inventory.ps1` sau khi thêm/xóa/thay asset.
- Ghi dữ liệu đã xác minh vào `docs/assets/provenance_overrides.csv`; generator sẽ giữ dữ liệu này qua lần chạy sau.
- `tools/check_asset_inventory.ps1` đối chiếu set file, byte size và SHA-256; nó được gọi bởi `tools/check_project.ps1`.
- `docs/.gdignore` ngăn Godot import nhầm CSV/JSON tài liệu thành runtime resource.

U0.4 đã phân loại đủ 166/166 file trong `docs/assets/asset_actions.csv`: 69 runtime asset là `VERIFY_OR_REPLACE/P0`; 27 file `HOLD_FOR_REVIEW/P2`; 1 duplicate `DEDUP_AFTER_REFERENCE_AUDIT/P2`; 69 scratch/preview/intermediate là `REMOVE_AFTER_REFERENCE_AUDIT/P3`. Chi tiết owner và thứ tự thay thế nằm trong `docs/assets/REPLACEMENT_PLAN.md`. Chưa file nào bị xóa hoặc di chuyển.

- Thay quyết định curated trong `asset_action_overrides.csv`, sau đó chạy `tools/generate_asset_triage.ps1`.
- `tools/check_asset_actions.ps1` bắt buộc mọi manifest row có action/priority/owner/rationale và mọi runtime asset chưa verified vẫn P0.

## Manifest tối thiểu

Mỗi package: `package_id`, `title`, `version`, `source_page`, `download_url`, `author`, `license_spdx`, `downloaded_at`, `archive_sha256`, `files_sha256`, `art_grid`, `intended_use`, `validation`, `derived_from`, `notes`.

Asset hiện hữu chưa có provenance phải đánh `UNKNOWN/QUARANTINE` cho tới khi đối chiếu. Không phát hành commercial với asset UNKNOWN.
## Candidate cho Paloria Luminous Town

Research ngày 2026-10-04 đã ghi candidate CC0: PixelKensei Feudal Japan Props Vol.2, Kenney Tiny Town, JRPG Pack 2 Towns, Emotional Piano và Sunset Plains. Sakura Shrine Village chỉ là lựa chọn trả phí/custom terms, có AI-assisted disclosure và cần người dùng mua/chấp nhận riêng.

Chưa có file nào được tải. game-dev CLI vẫn không có trong PATH nên package admission đang bị chặn. Danh sách URL, fit/risk, district plan, player/pet replacement, audio contract và thứ tự AT0–AT7 nằm trong roadmap/ANIME_TOWN_RENEWAL.md.

Quy tắc IP: “Your Name” chỉ là mood reference. Không tải hoặc tái tạo soundtrack, sprite, nhân vật, logo, địa điểm hay frame nhận diện được từ phim. Production ưu tiên map/character/pet nguyên bản và asset có provenance rõ.
