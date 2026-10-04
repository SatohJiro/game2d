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

## Manifest tối thiểu

Mỗi package: `package_id`, `title`, `version`, `source_page`, `download_url`, `author`, `license_spdx`, `downloaded_at`, `archive_sha256`, `files_sha256`, `art_grid`, `intended_use`, `validation`, `derived_from`, `notes`.

Asset hiện hữu chưa có provenance phải đánh `UNKNOWN/QUARANTINE` cho tới khi đối chiếu. Không phát hành commercial với asset UNKNOWN.
