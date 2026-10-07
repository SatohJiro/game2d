# Catalog gameplay và tính năng

## Trụ cột sản phẩm

1. Khám phá world rộng có biome, nguy hiểm và tài nguyên khác nhau.
2. Tìm, chiến đấu và thu phục sinh vật gốc của Paloria.
3. Nuôi pet, xây quan hệ và tạo đội hình chiến đấu/khám phá.
4. Xây căn cứ, trồng trọt, chăn nuôi và giao việc cho pet.
5. Tối ưu chuỗi sản xuất để mở vùng, công trình và thử thách mới.

Vòng chơi mục tiêu: **khám phá → thu thập/chiến đấu → thu phục → đưa pet về căn cứ → giao việc/sản xuất → chế tạo/nâng cấp → mở biome khó hơn**.

## Ma trận tính năng

| ID | Tính năng | Hiện trạng | Mục tiêu | Phase |
|---|---|---|---|---|
| G01 | Di chuyển, sprint, roll | Pure stamina/sprint/roll/velocity state; Player input/collision adapter | Input actions + remap/gamepad | U1/U3 |
| G02 | Survival needs | Pure needs state/snapshot; Player heat/HUD adapter; balance còn prototype | Tác động có telegraph và counterplay | U1/U5 |
| G03 | Gathering/loot | Pickup stable transaction; sphere miss-drop giữ stable ID; chest finite stack slots | Tool tiers, player capacity, yield table, respawn state | U1/U5 |
| G04 | Combat | Player/WildCreature dùng deterministic DamageResult; status/pet/building còn legacy | Telegraph, skill loadout, unified faction/status | U1/U5 |
| G05 | Capture | Deterministic chance, stable sphere transaction và atomic ownership; species/party còn adapter legacy | Typed species, persistent roster, clear feedback | U1/U5 |
| G06 | Pet party/command | Capture tạo party entry có stable species ID; một active pet, stance đơn giản | Persistent PetInstance, command wheel, roles, synergy | U1/U5 |
| G07 | Pet work | Scan group và auto work | Job board, reservation, suitability, needs | U5 |
| G08 | Farming | Plot/crop stages trong resource node; `crop.berry` typed mirror chưa nối runtime | Soil/moisture/crop definitions/season-lite | U1/U5 |
| G09 | Ranch | Assigned pet dictionary, timed output | Welfare, breeding/produce traits sau MVP | U5 |
| G10 | Craft/processing | Recipe dictionaries; `recipe.pal_sphere.basic` typed mirror chưa nối runtime | Queue, station capability, cancel/refund rules | U1/U5 |
| G11 | Building/base | Chest atomic batch cho wood/ore/berry; workbench typed mirror; placement prototype | Grid/socket, repair, storage/logistics | U1/U5 |
| G12 | Progression/quests | Level, stats, 5 base levels prototype | Data-driven unlock graph/objectives | U5 |
| G13 | Day/night/raid/boss | Main-script timers | World clock, schedules, encounter director | U2/U5 |
| G14 | World/biomes | Scene tĩnh 3.200×3.200 | Chunked biomes, discovery, fast travel | U2 |
| G15 | UI/settings/accessibility | HUD/crafting modal prototype | Theme, navigation, scale/remap/reduced motion | U3 |
| G16 | Save/load | Chưa có | Versioned atomic save + migration | U1/U6 |

## Luật và acceptance criteria

### G01 — locomotion

- Input: move vector, sprint held, roll pressed; UI focus/pause phải chặn gameplay input đúng policy.
- Sprint chỉ hoạt động khi đang di chuyển và đủ stamina; stamina không âm và hồi theo rule nhất quán.
- Roll có cooldown, khoảng invulnerability hữu hạn và không đi xuyên collision world.
- U1.6b: movement input là typed snapshot; roll là atomic command; external recoil/knockback đi vào calculation qua current velocity và roll có precedence khi active.
- U1.6c: discrete/held action đều qua stable `player.action.*` intent; mapper giữ build precedence và guard attack/roll theo modal.
- Acceptance: keyboard/gamepad cho cùng kết quả; chuyển hướng không làm animation giật; 60 giây spam roll không kẹt state.

### G02 — survival

- Hunger/thirst giảm theo game clock; sprint/work/combat có modifier được data hóa.
- Threshold phải báo trước bằng HUD/SFX; penalty không xuất hiện trước warning.
- Nguồn nhiệt, thức ăn và nước tạo effect có duration và stacking rule rõ.
- U1.6a dùng stable buff ID `needs.buff.*`, một buff active tại một thời điểm; display text chỉ là presentation adapter. Rate và threshold hiện giữ nguyên prototype.
- Acceptance: pause không drain; save/load giữ giá trị/effect; tất cả stat clamp `[0, max]`.

### G03 — gathering và loot

- Resource nhận tool/damage tag hợp lệ, giảm durability/health và phát yield khi depleted đúng một lần.
- Drop dùng item ID, stack count dương; pickup vào inventory theo transaction.
- Resource world có persistent state/cooldown khi chunk unload.
- Mapping `Gỗ` → `item.wood` đã chạy trong ResourceNode/drop/Player; các item và consumer khác vẫn theo legacy adapter plan.
- Acceptance: hai hit cùng frame không nhân đôi loot; inventory đầy để item còn ở world; pet/player dùng chung yield rule.

### G04 — combat

- Nhịp attack: anticipation → active/contact → recovery. Telegraph của enemy phải đọc được trước hit.
- Element/status, critical và defense tính trong CombatSystem; animation chỉ biểu diễn result.
- Player, wild creature, pet và turret dùng cùng damage contract với faction/filter rõ.
- U1.5 đã migrate target Player/WildCreature và khóa duplicate defeat; source caller vẫn đi qua signature adapter cũ.
- U1.8a giới hạn player perception ở cadence 0,20 giây, chọn candidate deterministic và bỏ group scan trong protected state; ngưỡng aggro/suspicion/sleep giữ nguyên.
- U1.8b chuyển 5 block IDLE/WANDER/SUSPICIOUS/CHASE-loss sang pure transition result + guarded apply; attack callback chỉ recover nếu actor vẫn ở ATTACK.
- U1.8c đóng perception entry, SLEEP/DRINKING/GRAZING/ALERT/FLEE timeout và capture rejection qua cùng apply owner; presentation chỉ chạy sau accepted apply. Skill/ecology writer được hoãn có owner sang U1.9.
- U1.9a: Flam dùng typed `CreatureDefinition` làm authority cho base HP/speed/power, predator/prey profile và stable drop reference; runtime legacy snapshot giữ nguyên behavior/balance cho consumer cũ.
- U1.9b: `skill.flam.fireball` là typed authority cho cooldown, recovery, damage scale, projectile travel và hit radius; giá trị gameplay quan sát được không đổi.
- U1.9c: Flam defeat drop dùng injected count roll và deterministic result; normal 1–2, elite/alpha 3–5 primary cộng bonus 2–4 giữ nguyên, capture/duplicate không phát loot.
- U1.9d: low-HP prey panic sau damage dùng pure ecology policy và transition owner; ngưỡng strict `<35%`, FLEE 3.5 giây, neutral/defeated/enraged/capture giữ nguyên rule cũ.
- U1.9e: predator chọn prey gần nhất trong `<210px`, bỏ capture-active và tie-break deterministic; scan cadence 2.0–3.5 giây, hunt 6 giây và feedback giữ nguyên.
- U1.9f: prey grazing dùng injected roll strict `<0.22` và transition owner; duration 2.5–4.0 giây cùng sleep→drink→grazing→wander RNG precedence giữ nguyên.
- U1.9g: săn mồi thoát qua stable abort/contact events; invalid/timeout về IDLE 2 giây, contact strict `<42px` gây damage ×0.7 rồi recovery 3 giây, với stale/protected guard.
- U1.9h: prey gặp predator vào FLEE 4 giây qua stable transition, giữ threat target và feedback; CAPTURING/FLEE/invalid predator không thay đổi lifecycle.
- U1.9i: peaceful creature ngủ khi roll strict `<0.18`, duration 6–11 giây qua transition owner; night-raider/enraged không tiêu thụ sleep RNG và precedence tự nhiên giữ nguyên.
- U1.9j: creature có hồ trong strict `<320px` uống khi roll strict `<0.25`, duration 3–5 giây; hướng tới hồ và presentation chỉ commit sau accepted transition.
- U1.9k: Slime giữ nguyên 110 HP, speed 85, power 9 và prey role nhưng các giá trị này lấy từ `creature.slime` typed definition; hop/drop outcome chưa đổi.
- U1.9l: Mushroom giữ nguyên 90 HP, speed 95, power 11, prey role và Hạt Giống drop nhưng các giá trị gameplay lấy từ typed definition; spore execution chưa đổi.
- U1.9m: Beast giữ nguyên 130 HP, speed 115, power 16, predator role và Thịt Tươi drop nhưng các giá trị gameplay lấy từ typed definition; charge/drop execution chưa đổi.
- U1.9n: Dragon giữ nguyên 340 HP, speed 95, power 26, predator role, forced-elite scaling và Thỏi Pal drop nhưng base values lấy từ typed definition; melee/fireball/drop execution chưa đổi.
- U1.9o: Dragon fireball giữ cooldown 2,2 giây, recovery 0,3 giây, damage ×1, travel 240 px/0,55 giây và radius 45 px qua `skill.dragon.fireball`; melee priority/range và presentation không đổi.
- U1.9p: Mushroom spore giữ cooldown 2 giây, recovery 0,25 giây, damage ×1, travel 200 px/0,5 giây và radius 45 px qua typed definition; kiting/escape không đổi.
- U1.9q: Slime hop giữ cooldown 1,15 giây, velocity 260, height 12px và tween 0,15/0,12/0,15/0,10 giây qua typed movement skill.
- U1.9r: Beast charge giữ range 70–220px, telegraph 0,45s, cooldown 3,5s, speed 330, duration 0,95s và stun 1,4s qua typed charge skill.
- U1.9s: Beast/Dragon melee dùng identity riêng, giữ activation 38/48px, cooldown 1,2s, lunge 180, contact 55px, damage ×1 và anticipation 0,2s.
- U1.9t: mọi species defeat drop dùng typed item ID và atomic result; normal 1–2 primary, elite/alpha 3–5 primary cộng Pal Ore 2–4, capture/duplicate không phát loot.
- U1.9u: burn gây 8 damage mỗi 0,8 giây qua combat result; capture pause tick, text/flash giữ nguyên và lethal tick chỉ commit defeat/reward một lần.
- Acceptance: một activation không multi-hit ngoài thiết kế; chết chỉ phát reward một lần; reduced shake không đổi damage.

### G05 — capture

- Chỉ wild creature hợp lệ mới nhận CaptureRequest. Chance phụ thuộc species difficulty, HP ratio, status và sphere modifier.
- UI hiển thị chance/quality theo rule thực; RNG có seed/log phục vụ test.
- U1.7a resolve một injected roll trước animation; sleep/back-strike được snapshot trước state transition và result chứa chance/tags cho presentation.
- U1.7b ưu tiên sphere Giga → Mega → Basic, chỉ trừ một item sau khi projectile đã validate; miss trả drop cùng stable item ID.
- U1.7c resolve rarity/trait từ hai roll đã inject, commit party/reward một lần và chỉ despawn wild creature sau accepted. Invalid/unknown/duplicate giữ roster và reward nguyên vẹn.
- Success tạo PetInstance và cập nhật roster trước khi wild node biến mất. Party đầy chuyển về storage/base theo policy tương lai.
- Acceptance: roll biên 0/1 xác định; thất bại không duplicate sphere/reward; save/load giữ captured pet.

### G06 — pet party và command

- Mỗi pet có persistent unique ID; active slot tham chiếu ID, không tham chiếu Node trong save.
- U1.10a: capture tạo `PetInstance` projection có unique `pet.*` ID và stable `creature.*` species ID; roster legacy vẫn giữ một backing dictionary để summon/ranch tương thích.
- U1.10b: phím slot vẫn chọn roster index nhưng lifecycle theo instance ID; chọn lại pet đang active không respawn, đổi pet bảo đảm tối đa một companion node trong tree.
- U1.10c: pet command hiện tại đi qua `pet.command.cycle_stance`, deterministic cycle auto-work → combat-assist → follow-protect; request sai không đổi stance.
- U1.10d: gameplay có explicit command đặt auto-work/combat-assist/follow-protect; gửi lại stance đang active là no-op, không reset AI hay phát presentation lặp.
- Command: follow, guard, attack, work, return; feedback xác nhận pet đã nhận hoặc lý do từ chối.
- Pet downed không bị xóa vĩnh viễn ngoài mode được thiết kế; recovery rule phải hiển thị.
- Acceptance: đổi active pet không duplicate node; unload/load giữ roster; command không override job đang commit mà thiếu cancel result.

### G07 — pet work automation

- Job gồm type, target, priority, required capability, reservation owner và expiry.
- Pet chọn job theo suitability, distance, need và priority; một target không bị nhiều pet claim sai.
- Chu trình: acquire → travel → work → deposit → rest/eat. Mỗi bước có timeout/recovery.
- Acceptance: 5 pet/20 job không deadlock; target bị xóa giải phóng reservation; output bảo toàn qua save/load.

### G08 — farming

- Planting tiêu seed qua transaction; crop progress theo game clock và điều kiện moisture/fertilizer.
- Visual stage được suy ra từ progress; harvest phát yield một lần rồi reset/transition đúng crop rule.
- Pet watering/planting/harvest dùng cùng command với player.
- Acceptance: pause không grow nếu clock dừng; reload không reset progress; fertilizer không stack vô hạn.

### G09 — ranch

- Assignment dùng pet unique ID và capacity; pet không đồng thời ở party active và ranch nếu policy không cho phép.
- Production cần thời gian, thức ăn/welfare và trait phù hợp; output đi qua inventory/storage transaction.
- Breeding/egg là post-MVP, chỉ thêm sau khi roster/save ổn định.
- Acceptance: thiếu thức ăn dừng với feedback; unassign giữ pet state; output không mất khi storage đầy.

### G10 — crafting và processing

- RecipeDefinition chứa input/output/station/time/unlock. Start order reserve nguyên liệu atomically.
- Cancel/refund policy ghi trong recipe/station; complete không thể chạy hai lần.
- Workbench, furnace, cooking pot và compost dùng CraftOrder chung với adapter capability.
- Acceptance: nguyên liệu thiếu không đổi state; save giữa chừng resume đúng; output đầy chuyển pending thay vì mất.

### G11 — building và base

- Preview biểu diễn valid/invalid; placement kiểm tra terrain, collision, bounds, cost và unlock.
- Build commit trừ cost và spawn entity trong một transaction logic; cancel không tốn cost.
- Building có stable instance ID, health, repair/dismantle policy và state riêng theo subtype.
- U1.12e: chín placement reachable có stable subtype/instance identity; U1.12f–s giữ mutable state qua turret structure durability. Workbench health chưa persist.
- Acceptance: không overlap vùng cấm; reload giữ transform/state; dismantle trả đúng bảng refund.

### G12 — progression và quests

- EXP/unlock nhận event domain; objective không scan world liên tục.
- QuestDefinition dùng objective IDs/counts và reward transaction. Claim một lần.
- Base level mở capacity/building/biome rõ; không chỉ tăng số mà thiếu lựa chọn.
- U1.12d: năm quest base có stable `quest.base.*`; claimed ledger được lưu để load không reset hoặc phát reward lặp. Objective/reward/unlock hiện hữu giữ nguyên.
- Acceptance: event trước khi nhận quest theo policy đã định; save/load không claim lại; content thiếu ID báo lỗi validator.

### G13 — time, raid và boss

- WorldClock là nguồn thời gian duy nhất cho day/night/schedule; pause policy rõ.
- EncounterDirector dùng budget/condition/cooldown, không spawn boss chỉ bằng timer hardcode.
- Raid telegraph, preparation window, win/lose condition và reward rõ.
- Acceptance: không spawn trùng khi reload; raid ngoài loaded chunk có policy; boss defeat persist.

### G14 — world rộng

- Chunk load quanh player theo radius và budget; persistent delta hiện giữ static tree/rock health/respawn và player-built state, còn spawn/chunk admission thuộc U2.
- Biome definition sở hữu terrain palette, spawn table, ambience, resource và hazard.
- Fast travel chỉ tới point đã khám phá và commit save trước transition.
- Acceptance: đi qua ít nhất 9 chunk liên tục; quay lại giữ thay đổi; soak 20 phút không tăng node/memory vô hạn.

### G15 — UI và accessibility

- HUD luôn: HP/stamina/quickbar; dữ liệu ngữ cảnh hiển thị khi cần. Modal giữ focus và có back/cancel.
- Keyboard, mouse, gamepad; remap input; UI scale; reduced motion/flash/shake; trạng thái không chỉ phân biệt bằng màu.
- UI đọc ViewModel và phát intent, không gọi mutation gameplay trực tiếp.
- Boundary U1.6c cho phép UI/InputMap tương lai phát cùng `PlayerActionIntent`; physical-key mapper hiện là compatibility adapter, chưa phải remap system.
- Acceptance: hoàn tất vòng capture/build/craft không cần chuột; 720p–1440p không cắt UI; đổi device cập nhật prompt.

### G16 — persistence

- Save chứa schema version, slot metadata, world delta và DTO từng module; không chứa Node/Callable.
- Atomic write, checksum/backup và migration tuần tự. Autosave tránh giữa transaction domain.
- U1.11a: Save v1 envelope có version, metadata và player/inventory/pets/world DTO; validator từ chối localized identity, duplicate/stale pet reference và Node/Callable/Vector2.
- U1.11b: runtime snapshot giữ player needs/progression/position, stable inventory, pet roster/active stance và world clock; source không mutate, unknown inventory key chặn snapshot.
- U1.11c: load apply chỉ commit sau khi schema và mọi item/species/stance reference được resolve; lỗi giữ nguyên Player/inventory/roster/active pet, world clock trả về cho owner thay vì save module tự mutate scene.
- U1.11d: repository chỉ promote JSON đã validate qua temporary; giữ một backup hợp lệ và đọc fallback không tự sửa file. Invalid/corrupt data không được apply vào gameplay.
- U1.11e: migration chỉ chấp nhận route tuần tự duy nhất tới current schema và validate output cuối; version tương lai, missing/cycle/ambiguous step đều không được vào runtime.
- U1.11f: explicit coordinator dừng pipeline ngay khi snapshot/repository/migration/apply lỗi; load success báo primary/backup và trả clock cho world owner. Chưa tự autosave hoặc gọi từ UI.
- U1.12w: Main là world-clock owner; explicit save truyền `day_time`, explicit load chỉ commit clock và refresh ambient sau success. Failed load giữ clock; raid/boss/spawn timers chưa persist.
- U1.12x: raid-cycle guard đi cùng clock; load giữa đêm sau raid không spawn raid lặp. Raid actor, boss và spawn timers chưa persist.
- U1.12b: 25 inventory key reachable trong core/crafting/farming/ranch/cooking đều project sang stable `item.*`; regression từng nhóm bảo đảm output gameplay hợp lệ không làm save thất bại. Unknown key vẫn bị từ chối nguyên khối.
- U1.12c: rarity, trait và stance của từng pet dùng stable ID; save/load giữ metadata và command stance cho cả pet active lẫn inactive. Badge/name localized chỉ là presentation; roll, multiplier và hành vi pet không đổi.
- U1.12d: Save v1 giữ base level, active stable quest ID và claimed quest IDs; state skip/mâu thuẫn hoặc localized title fail closed, apply không phát reward.
- U1.12l: active altar restore đúng một boss ID/HP, không thu offering hoặc phát completion giả; idle/stale và HP ngoài range fail closed.
- U1.12m: turret restore cooldown còn lại mà không bắn khi load hoặc giữ stale target; target/projectile runtime không thuộc save.
- U1.12n: chest inventory và health 1–250 round-trip cùng nhau; load không gọi damage/destruction, invalid health không thay runtime state.
- U1.12o: furnace processing và health 1–300 round-trip cùng nhau; load không tick smelting hoặc gọi destruction, invalid health fail atomic.
- U1.12p: cooking pot có durability foundation 200 HP; recipe/progress/health round-trip không finish/reward khi load và invalid health fail atomic.
- U1.12q: ranch assignment/food/progress/health 1–350 round-trip; load dựng đúng animal presentation nhưng không production/reward, invalid health fail atomic.
- U1.12r: altar health 1–1000 độc lập boss HP; active restore đúng một boss và không summon/completion/destruction side effect, invalid structure health fail atomic.
- U1.12s: turret cooldown/health 1–350 round-trip; load không fire/destruction hoặc giữ stale target, invalid health fail atomic.
- Acceptance: save → quit → load giữ inventory, roster, assignment, building, crop, quest và world clock; corrupt file trả lỗi an toàn.

## Thứ tự ưu tiên playable vertical slice

1. Data IDs + inventory transaction.
2. Một creature definition xuyên suốt combat → capture → roster → summon.
3. Một farm plot + một job pet → output vào chest.
4. Một building placement + một processing recipe.
5. Save/load cho toàn slice.
6. Sau khi slice ổn định mới nhân content, mở world và nâng UI/art.
