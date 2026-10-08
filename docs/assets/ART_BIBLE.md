# Paloria Art Bible v1.0

Chuẩn mỹ thuật cho mọi asset gốc của Paloria 2D. Asset ngoài (vendor) nằm ở
`assets/vendor/<package>` và không bao giờ bị ghi đè; asset game gốc nằm ở
`assets/game/` hoặc các thư mục category hiện tại sau khi được thay thế có
provenance sạch.

## 1. Pixel grid

- Đơn vị cơ sở: **16 px**. Mọi sprite là bội số của 16; particle/vệt FX nhỏ cho phép
  bội số của **8 px** (dust, leaf, spark 8×8; shadow 24×12).
- Item icon: **16×16**.
- Building/prop: **32×32** (một số 48×48 = 3×16).
- Floor tile: **64×64** (4×16), tile liền mạch (seamless) theo cả 4 cạnh.
- FX strip: các frame 16×16 / 24×24 / 32×32 xếp ngang, số frame ghi trong tên hoặc metadata.
- Character/monster sheet: frame **16×16**, **4 cột** (frame animation) × N hàng
  (hướng/hành động). Ví dụ player: 4×7 (4 hướng di chuyển + windup + strike + row phụ).
- Không xoay/lệch nửa pixel; sprite căn theo lưới, neo giữa-đáy cho actor.

## 2. Palette — "Paloria-16"

Mọi sprite gốc chỉ dùng các màu trong bảng này (alpha 0 cho nền trong suốt):

| Tên | Hex | Dùng cho |
|---|---|---|
| outline | `#1d2433` | viền ngoài 1 px |
| ink_soft | `#3a4356` | viền trong, chi tiết tối |
| skin | `#f2c99b` | da |
| skin_shade | `#d69e6d` | bóng da |
| leaf | `#4fae4f` | lá, cỏ sáng |
| leaf_dark | `#2f7d3a` | lá tối, bóng cỏ |
| wood | `#a9744f` | gỗ |
| wood_dark | `#7a5233` | gỗ tối |
| stone | `#9aa3b2` | đá |
| stone_dark | `#6b7280` | đá tối |
| water | `#3fa7d6` | nước |
| water_dark | `#2474a3` | nước sâu |
| fire | `#f2812e` | lửa, cam accent |
| gold | `#f2c230` | vàng, coin, accent UI |
| berry | `#d6405e` | quả mọng, đỏ |
| cloth | `#4f6fb5` | vải xanh |
| snow | `#eef3f8` | trắng sáng, highlight |

Quy tắc: viền `outline` 1 px quanh silhouette; 1 màu bóng (shade) cho mỗi mảng lớn;
highlight tối đa 2 px mỗi mảng; không dither quá 1 px xen kẽ.

## 3. Filtering & import

- `default_texture_filter=0` (Nearest) toàn project — không đổi.
- Không mix pack khác style khi chưa normalize qua pipeline này.

## 4. Animation

- Locomotion: **8 FPS**, 4 frame/cycle (đi, chạy).
- Combat: **10–12 FPS**; mỗi đòn có 3 pha: **anticipation** (windup ≥ 0.15s,
  flash/telegraph), **contact** (1 frame hit + VFX + SFX marker), **recovery**
  (≥ 0.2s trước khi nhận input tiếp).
- Capture: bóng rung 3 nhịp, mỗi nhịp 0.4s, marker rung đồng bộ SFX.
- Không tạo chuỗi boolean animation mới; actor nhiều state dùng AnimationTree.
- VFX gắn marker, không quyết định kết quả gameplay.

## 5. Audio

- SFX: WAV 16-bit mono 22050 Hz, ≤ 1.5s, peak −3 dB.
- Music: OGG loop liền mạch, ≤ 4 phút, −14 LUFS tương đối.
- Mọi SFX đăng ký trong `AudioManager.sounds` và có mặt trong audio event map
  (`docs/assets/AUDIO_MAP.md`).

## 6. Đặt tên & provenance

- `snake_case`; sheet animation hậu tố `_sheet`; hàng lẻ `row_<n>`.
- Mọi asset gốc: provenance `GENERATED`, license `CC0-1.0`, receipt trong
  `docs/assets/receipts/` ghi công cụ + ngày + SHA-256 + mục đích sử dụng.
