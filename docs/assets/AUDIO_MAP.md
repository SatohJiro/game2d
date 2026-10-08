# Audio event map

Mọi sự kiện âm thanh của game. SFX đăng ký trong `AudioManager.sounds`;
file nguồn là asset gốc CC0 (xem `docs/assets/receipts/u4.2-original-assets.md`).
Volume đi qua Master bus → `GameSettings.master_volume`.

## SFX

| Event | File | Trigger |
|---|---|---|
| `slash` | `assets/sfx/sword.wav` | Player vào pha strike (contact marker) |
| `hit` | `assets/sfx/hit.wav` | Player/creature nhận damage |
| `sphere_throw` | `assets/sfx/fireball.wav` | Ném cầu bắt |
| `shake` | `assets/sfx/alert.wav` | Cầu rung / cảnh báo |
| `success` | `assets/sfx/success.wav` | Bắt thành công, craft/cooking xong |
| `level_up` | `assets/sfx/powerup.wav` | Lên cấp (player/pet) |
| `pickup` | `assets/sfx/coin.wav` | Nhặt item, thu hoạch |
| `jump` | `assets/sfx/jump.wav` | Nhảy / né đòn |

## Music

| Track | File | Dùng ở |
|---|---|---|
| `adventure_begin` | `assets/music/adventure_begin.ogg` | Nhạc nền chính (loop, autoplay khi không headless) |

Quy tắc: thêm event mới phải đăng ký trong `AudioManager._ready()` và thêm hàng
vào bảng này; validator `tools/validate_original_assets.gd` kiểm tra mọi entry
resolve được.
