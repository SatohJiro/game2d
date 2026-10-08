# AT Art Direction — Paloria Luminous Town

> Sáng kiến AT, bước AT0. Tên nội bộ: **Paloria Luminous Town**.
> Không sao chép địa điểm, nhân vật, soundtrack hay khung hình từ phim/IP khác.
> "Your Name" chỉ là tham chiếu cảm xúc do người dùng cung cấp.

## Shape language

- Mái nhà: tam giác thoải, diềm mái cong nhẹ, lợp ngói xanh lam/xám.
- Cửa sổ: hình chữ nhật đứng, khung gỗ, sáng đèn vàng về đêm.
- Cổng torii đền: cột đỏ son (`#c0392b`), xà cong.
- Cầu: vòm gỗ đơn giản, lan can thấp.
- Dây điện: đường cong võng giữa cột, có chim đậu ban ngày.
- Motif Paloria: ngôi sao 5 cánh cách điệu, tinh thể Pal, chuông gió.

## Palette mở rộng (bổ sung Paloria-16)

| Tên | Hex | Dùng cho |
|---|---|---|
| roof_blue | `#3f5f8a` | mái nhà |
| roof_shadow | `#2c4463` | bóng mái |
| plaster | `#f0e6d2` | tường |
| plaster_shadow | `#d9c9a8` | bóng tường |
| torii_red | `#c0392b` | cổng đền, accent |
| lantern_paper | `#f7d9a0` | đèn lồng giấy |
| lantern_glow | `#ffb347` | ánh đèn |
| sakura | `#f2a7c3` | hoa anh đào |
| sakura_dark | `#d67f9e` | bóng hoa |
| night_indigo | `#2b3355` | trời đêm |
| dusk_orange | `#f2812e` | hoàng hôn (đã có fire) |
| dusk_purple | `#7a5fa0` | mây hoàng hôn |
| rain_grey | `#8a94a6` | trời mưa |

## Ánh sáng

- Hướng sáng trên-trái, nhất quán mọi sprite.
- Ngày: trắng ấm; hoàng hôn: cam/hồng/tím; đêm: indigo + đèn vàng; mưa: giảm saturation.
- Cửa sổ/đèn đường/đèn lồng: PointLight2D, chỉ bật khi trời tối (phase dusk_late/night/dawn_early).

## Quận (districts)

| ID | Tên | Chunk | Gameplay anchor |
|---|---|---|---|
| `farm_edge` | Rìa nông trại | (0,0) | base camp hiện tại: farm, ranch, workbench |
| `station_plaza` | Quảng trường ga | (1,0) | fast travel, tháp đồng hồ |
| `market_street` | Phố chợ | (1,0) | shop stalls, bulletin board |
| `hillside` | Khu dân cư dốc | (2,0) | nhà dân, máy bán hàng, shortcut |
| `shrine_hill` | Đền trên đồi | (1,-1) | rare capture, vista hoàng hôn |
| `lakeside` | Bờ hồ | (1,1) | fishing, water-pet |
| `outskirts_*` | Vùng ven | còn lại | rừng/mỏ, combat/resource |

## Quy tắc

- Mọi structure có collision đọc rõ (không che interactable/telegraph).
- Occluder (mái nhà) fade khi player đi sau.
- Text mới qua localization keys; tên quận có vi/en.
