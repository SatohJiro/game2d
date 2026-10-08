# Player progression persistence contract — U1.12ai–aj

## Hiện trạng đã quan sát

`player.gd` giữ level/EXP cùng `max_exp`, hai điểm stat mỗi level, bốn stat `str/vit/sta/agi`, weapon legacy và armor bool. `recalculate_stats()` derive max HP/stamina/speed; crafting gán localized weapon name và damage trực tiếp. `PlayerNeedsState` đã có stable buff ID nhưng maxima và buff duration chưa thuộc Save v1.

Save v1 hiện chỉ giữ level/EXP, current HP/max HP, current stamina và current hunger/thirst/temperature. Vì vậy load có thể ghép level/EXP đã lưu với threshold, allocation, gear hoặc buff mặc định. U1.12ai chỉ tạo pure contract; chưa đổi Save schema/snapshot/apply hoặc runtime Player.

## Typed state và invariant

`PlayerProgressionState` chứa `level`, `exp`, `max_exp`, `stat_points`, đúng bốn stat, stable `weapon_id`/`armor_id`, derived `max_hp`/`max_stamina`, needs maxima, stable `buff_id` và remaining duration.

- `level >= 1`; `max_exp` phải đúng chuỗi runtime bắt đầu 100 và mỗi level dùng `int(previous * 1.4)`; `0 <= exp < max_exp`.
- Tổng allocation cộng điểm chưa dùng phải bằng `level * 2`; mọi stat là integer không âm.
- Max HP phải bằng `100 + (level - 1) * 18 + vit * 25 + armor bonus`; max stamina bằng `100 + sta * 15`.
- Hunger/thirst maxima hữu hạn và dương. Buff rỗng phải có duration 0; buff allowlist phải có duration `(0,240]`.
- `PlayerEquipmentCatalog` allow stable weapon/armor IDs và sở hữu projection damage/HP bonus hiện tại.

## Identity và boundary

Weapon: `equipment.weapon.wood_sword`, `equipment.weapon.iron_sword`, `equipment.weapon.pal_blade`. Armor: `equipment.armor.none`, `equipment.armor.pal_warrior`. Localized `weapon_name`, crafting short ID, asset path và `weapon_damage` không phải identity/save authority; damage và armor bonus được derive từ catalog.

DTO chỉ dùng JSON-safe scalar/dictionary. `from_dto()` chấp nhận JSON float có giá trị nguyên cho integer field rồi chuẩn hóa, nhưng từ chối phân số/non-finite/unknown ID/incoherent budget hoặc maxima. `create_legacy_default(level, exp)` bảo thủ dùng zero allocation, toàn bộ budget chưa dùng, wood sword, no armor, default maxima và no buff.

## Scope, compatibility và admission gate

U1.12ai không mutate Player, gameplay rule hay Save v1. Admission package sau phải project/apply toàn bộ state atomically, map equipment stable ID sang presentation legacy, derive combat tuning và định nghĩa fallback cho Save v1 cũ thiếu metadata. Không serialize HUD, Node, Callable, cooldown/roll transient hoặc localized text.

Asset/provenance: none. Rollback: bỏ hai pure class, validator và docs U1.12ai; runtime/save hiện hữu không đổi.

## Save v1 admission — U1.12aj

`player.progression_state` nay chứa typed DTO. Snapshot map exact legacy name+damage sang stable weapon ID, armor bool sang armor ID, và đọc maxima/buff từ component state; unmapped hoặc incoherent runtime fail closed không trả partial snapshot.

Schema explicit bắt progression khớp `player.level/exp/max_hp` và current stamina/hunger/thirst không vượt maxima. Field thiếu từ Save v1 pre-release được nhận theo legacy policy: `create_legacy_default(level, exp)` tạo zero allocation, toàn bộ điểm chưa dùng, starter gear/default maxima và no buff.

Apply resolve DTO trước mutation, sau đó derive lại localized weapon presentation, damage và armor bool từ catalog; stat/maxima/buff được commit cùng scalar Player. Legacy current HP/stamina/needs được clamp vào default maxima. Invalid DTO bị reject trước runtime mutation. Shape vẫn version 1 vì chưa phát hành; thay đổi sau phát hành phải tăng version/migration.
