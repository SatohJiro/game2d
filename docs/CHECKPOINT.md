# Checkpoint triển khai Paloria 3.0

## U1.9b — Flam typed skill canary

Trạng thái: `VERIFIED` ngày 2026-10-05.

### Mục tiêu và invariant

- Dùng stable ID và typed definition/reference cho đúng một attack canary của Flam.
- Giữ nguyên cooldown, damage, projectile travel/hit guard và async recovery hiện có.
- Không đổi asset, balance, collision, spawn, capture, ecology, drop hoặc save schema.

### Kết quả đã triển khai

- Thêm `SkillDefinition` và `skill.flam.fireball`; `CreatureDefinition.skill_ids` tham chiếu stable ID và tham gia registry cross-reference.
- `LegacySpeciesAdapter.get_primary_skill_definition()` là compatibility boundary cho Flam; species chưa migrate vẫn nhận `null` và chạy legacy values.
- `WildCreature.perform_fireball_attack()` nhận typed definition cho Flam, trong khi Dragon/default legacy call giữ fallback cũ.
- Giá trị giữ nguyên: cooldown 2.2s, recovery 0.3s, damage ×1, travel 240px/0.55s, hit radius 45px.
- Audit đã phân loại Slime hop, Mushroom spore, Beast charge, Dragon selection, generic/prey melee sang package sau; không mở rộng scope.

### Validation hiện tại

- Baseline full `tools/check_project.ps1` xanh trước thay đổi.
- Focused content regression xanh: invalid fields, missing skill reference, catalog 12 definitions và Flam reference/value assertions.
- Focused creature actor regression xanh: actor resolve stable skill và toàn bộ compatibility values.
- Full final `tools/check_project.ps1` xanh: documentation/asset gates, editor load, toàn bộ domain regression và main-scene smoke.
- `git diff --check` sạch; final log scan không có `SCRIPT ERROR`, `Parse Error`, missing dependency hoặc invalid node path.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; không serialize Resource/Node và không đổi party snapshot.
- Asset/provenance: không thêm/sửa asset; 166 asset baseline vẫn quarantine/unknown, 69 runtime P0.
- Presentation telegraph text/audio/texture còn trong actor; typed skill không quyết định animation hay VFX.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
- Rollback: revert package U1.9b; không cần migration.

### Gói tiếp theo

U1.9c xử lý một lát cắt nhỏ của ecology/drop ownership hoặc một skill writer kế tiếp sau khi xác nhận dependency; không gom cả hai migration vào cùng package. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.

## Hướng sản phẩm phải giữ

- Definition dùng stable ID và không lưu Node/ObjectID, sẵn sàng cho save/chunk U2.
- Combat result là deterministic domain result; animation/VFX chỉ trình bày event.
- Paloria Luminous Town vẫn là initiative U2–U4; content phát hành phải nguyên bản và có provenance.
