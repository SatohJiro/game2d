# Checkpoint triển khai Paloria 3.0

## U1.7c — stable species và atomic roster ownership

Trạng thái: `VERIFIED` ngày 2026-10-04; package branch `work/u1.7c-roster-ownership`.

### Mục tiêu và invariant

- Stable species ID đi xuyên capture request, ownership result và party entry.
- Rarity/trait được resolve thuần từ hai roll đã inject; resolver không gọi RNG hay Node.
- Accepted append/reward/quest đúng một lần; invalid/unknown/duplicate không mutation.
- Wild creature chỉ despawn sau accepted ownership; rejection phục hồi actor trong world.
- Giữ party dictionary và summon adapter hiện hữu; chưa tạo persistent PetInstance hay save schema.

### Kết quả đã triển khai

- `LegacySpeciesAdapter` map cố định 5 species legacy sang `creature.*` ID và deep-copy stable snapshot.
- `CaptureOwnershipRequest`, `CaptureOwnershipResult`, `CaptureOwnershipResolver` tạo boundary thuần, deterministic.
- Giữ đúng rarity threshold 0.05/0.20/0.45, multiplier 1.5/1.3/1.15/1.0 và reward 75 EXP.
- Player commit party entry có top-level `species_id`, chống token lặp trong phiên và chỉ chạy side effect sau accepted.
- WildCreature tạo token theo instance, lấy đúng hai roll cho ownership và chỉ `queue_free()` sau accepted.
- Rejection clear capture attempt, khôi phục visual và chuyển CHASE/IDLE an toàn.

Contract chi tiết: `architecture/CAPTURE_OWNERSHIP_CONTRACT.md`.

### File và API chính

- `data/legacy_species_adapter.gd`: mapping index ↔ stable ID và `create_stable_snapshot()`.
- `systems/capture/capture_ownership_request.gd`: immutable-by-convention input snapshot.
- `systems/capture/capture_ownership_result.gd`: `ACCEPTED | INVALID_REQUEST | UNKNOWN_SPECIES | DUPLICATE`.
- `systems/capture/capture_ownership_resolver.gd`: validation, rarity/trait, stat boost và party projection.
- `scripts/player.gd`: `on_pet_captured(...) -> CaptureOwnershipResult`, `commit_capture_ownership()`.
- `scripts/creature.gd`: `capture_succeeded(...) -> CaptureOwnershipResult`, rejection restore và duplicate guard.
- `tools/validate_capture.gd`: pure boundary và lifecycle regression.

### Validation hiện tại

- Focused capture regression đạt: deterministic chance, sphere transaction và atomic roster ownership.
- Full `tools/check_project.ps1` đạt: 26 required file, 30 Markdown file; 166 asset inventory/action; editor import/load, content, inventory, combat, needs, locomotion, action, capture và main-scene smoke đều xanh.
- Log scan không có script error, parse error, missing dependency, runtime error hoặc resource leak.

### Compatibility, save, asset và giới hạn

- Save/data breaking change: none. Dự án chưa lưu roster; party dictionary chỉ thêm `species_id`.
- Token `wild_capture_<instance_id>` và committed-token set chỉ tồn tại trong session, không phải persistent identity.
- Caller cũ chỉ truyền pet data/level giờ fail closed vì thiếu token/roll; runtime chính đã migrate.
- Asset/provenance: không thêm hoặc sửa asset; inventory 166 asset giữ nguyên.
- Manual editor test còn cần cho HUD/audio/timing reject-resume và summon party entry mới.
- Party chưa có capacity/storage policy; persistent PetInstance thuộc U1.10, save roster thuộc U1.11.
- Rollback: revert commit U1.7c; không cần migration.

### Gói tiếp theo

U1.8a chỉ tách creature perception cadence/query boundary và regression; không viết lại toàn bộ AI. Đọc `NEXT_UPDATE_PROMPT.md`, chạy full gate baseline, audit `_physics_process`, group scans và target acquisition trước khi sửa.

## Hướng sản phẩm phải giữ

- Paloria Luminous Town là initiative hình ảnh/world/audio ưu tiên sau khi U2 chunk/persistence contract ổn định.
- Kế hoạch AT0–AT7 ở `roadmap/ANIME_TOWN_RENEWAL.md`; dùng thiết kế nguyên bản, không sao chép map/sprite/nhạc của Your Name.
- Asset admission mới vẫn bị chặn vì `game-dev` CLI chưa có trong PATH.
