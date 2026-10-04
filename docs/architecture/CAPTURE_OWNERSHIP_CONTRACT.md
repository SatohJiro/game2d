# U1.7c — Capture ownership contract

Trạng thái: `VERIFIED` ngày 2026-10-04
Pure domain: `systems/capture/capture_ownership_*.gd`
Compatibility data: `data/legacy_species_adapter.gd`
Actor adapters: `scripts/player.gd`, `scripts/creature.gd`

## Mục tiêu và invariant

U1.7c tạo ranh giới atomic giữa kết quả bắt thành công và quyền sở hữu pet. Wild creature chỉ biến mất sau khi Player đã chấp nhận roster entry. Resolver không truy cập Node, SceneTree, RNG, HUD, audio hoặc inventory.

- Mỗi capture token chỉ được commit tối đa một lần trong một phiên chạy.
- Accepted append đúng một party entry, thưởng đúng 75 EXP và cập nhật quest đúng một lần.
- Invalid, unknown species và duplicate không đổi party, EXP hoặc quest.
- Wild creature chỉ despawn sau accepted; rejection khôi phục visual/state và giữ creature trong world.
- Resolver có cùng input thì cho cùng result và không sửa species snapshot đầu vào.
- Stable species ID đi xuyên request, result và party entry; display name và array index không phải identity lưu trữ.

Ngoài phạm vi: party capacity/storage policy, persistent pet instance ID, summon lifecycle mới, command UI, save/load roster, typed `CreatureDefinition`, seeded replay service và thay đổi animation.

## Stable species compatibility mapping

Runtime species hiện vẫn nằm trong mảng dictionary của `WildCreature`. `LegacySpeciesAdapter` là cầu nối có kiểm thử, chưa phải species catalog:

| Legacy index | Stable ID |
|---:|---|
| 0 | `creature.flam` |
| 1 | `creature.slime` |
| 2 | `creature.mushroom` |
| 3 | `creature.beast` |
| 4 | `creature.dragon` |

Index hoặc ID ngoài bảng fail closed. `create_stable_snapshot()` deep-copy dictionary và thêm `id`; không sửa dictionary nguồn.

## Request, result và thứ tự rule

`CaptureOwnershipRequest` chứa token, stable species ID, deep-copied species snapshot, level, hai roll đã inject trong `[0,1]` và cờ `already_committed` do owner của session token cung cấp.

`CaptureOwnershipResult.Status` gồm `ACCEPTED`, `INVALID_REQUEST`, `UNKNOWN_SPECIES`, `DUPLICATE`. Result accepted chứa deep-copied party entry, badge, trait, multiplier và reward EXP.

Resolver áp rule theo thứ tự:

1. Null request hoặc token rỗng → `INVALID_REQUEST`.
2. Token đã commit → `DUPLICATE`.
3. Species ID không có trong adapter → `UNKNOWN_SPECIES`.
4. Level không dương, snapshot rỗng, ID mismatch, name rỗng, power/max HP không dương hoặc roll không finite/ngoài `[0,1]` → `INVALID_REQUEST`.
5. Resolve rarity/trait, deep-copy snapshot, nhân `power` và `max_hp`, tạo party entry → `ACCEPTED`.

## Rarity, trait và reward

| Rarity roll | Badge | Multiplier | Trait |
|---|---|---:|---|
| `[0.00, 0.05)` | ★★★★ Thần Thoại | 1.50 | Thần Long Hộ Mệnh |
| `[0.05, 0.20)` | ★★★ Sử Thi | 1.30 | Chiến Tướng / Thần Tốc / Hộ Vệ |
| `[0.20, 0.45)` | ★★ Hiếm | 1.15 | Dũng Cảm / Nhanh Nhẹn |
| `[0.45, 1.00]` | ★ Thường | 1.00 | Bình Thường |

Trait index là `floor(trait_roll * option_count)`, clamp ở phần tử cuối để roll `1.0` hợp lệ. Power và max HP dùng phép nhân rồi cast `int`, giống behavior cũ. Reward accepted cố định là 75 EXP.

Các chuỗi badge/trait còn là presentation data trong party dictionary legacy. Package sau phải chuyển chúng thành stable IDs trước khi save schema coi roster là dữ liệu bền vững.

## Adapter và lifecycle

1. `WildCreature.setup_species()` tạo stable snapshot.
2. `capture_succeeded()` lấy token dạng `wild_capture_<instance_id>`; token chỉ ổn định trong lifetime hiện tại.
3. Nếu actor đã commit, trả `DUPLICATE` mà không lấy RNG hoặc gọi Player.
4. Actor lấy đúng hai `randf()` cho rarity và trait rồi gọi `Player.on_pet_captured(...)`.
5. Player tạo request, đánh dấu duplicate từ `committed_capture_tokens`, rồi gọi resolver.
6. Chỉ accepted mới append `pet_party`, lưu token, thưởng EXP, shake, HUD và quest progress.
7. Actor chỉ phát success feedback và `queue_free()` sau accepted.
8. Rejection clear active attempt, phục hồi visual và chuyển sang CHASE nếu Player hợp lệ, nếu không về IDLE.

`committed_capture_tokens` và token dựa trên instance đều transient. Chúng chặn callback lặp trong runtime, không phải save identity. U1.10 phải tạo persistent unique ID cho mỗi PetInstance; U1.11 phải lưu roster bằng DTO/versioned schema.

Party entry tương thích hiện tại:

```text
{
  species_id: StringName,
  species_data: Dictionary, # deep copy, có id/power/max_hp đã boost
  level: int,
  rarity_badge: String,
  trait: String
}
```

`species_id` top-level là identity mới. Các field legacy được giữ để `swap_active_pet()` và scene pet cũ tiếp tục hoạt động. Không có backing roster thứ hai.

## Compatibility, save, asset và rollback

- Save/data breaking change: none; dự án chưa có save roster. Party dictionary chỉ thêm field `species_id`.
- API compatibility: `on_pet_captured()` vẫn nhận hai tham số đầu cũ nhưng caller thiếu token/roll sẽ fail closed thay vì tự random và mutation ngầm.
- Asset/provenance: none.
- Rollback: revert commit U1.7c; dữ liệu lưu cũ không cần migration.
- Không đổi U1.7a chance resolver hoặc U1.7b sphere transaction.

## Validation và giới hạn

`tools/validate_capture.gd` kiểm tra mapping known/unknown/reverse; rarity boundary 0.05/0.20/0.45; trait roll 0/1; multiplier; immutability; deterministic repeat; invalid/mismatch/duplicate; accepted append/reward đúng một lần; rejected không mutation/despawn; accepted despawn; callback lặp không double reward.

Full gate: `tools/check_project.ps1`. Log chính: `build/checks/capture-validation.log`, `build/checks/headless-smoke.log`.

Cần manual editor test cho timing capture success/reject, HUD banner, audio, chase resume và summon bằng party entry có `species_id`. Party chưa có capacity policy; mọi capture hợp lệ hiện được nhận. Token chưa chống duplicate qua save/reload hoặc nhiều process.
