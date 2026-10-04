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
| G05 | Capture | Deterministic result + stable sphere selection/atomic spend; roster còn legacy | Species definition, atomic ownership, clear feedback | U1/U5 |
| G06 | Pet party/command | Một active pet, stance đơn giản | Roster, command wheel, roles, synergy | U1/U5 |
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
- Acceptance: một activation không multi-hit ngoài thiết kế; chết chỉ phát reward một lần; reduced shake không đổi damage.

### G05 — capture

- Chỉ wild creature hợp lệ mới nhận CaptureRequest. Chance phụ thuộc species difficulty, HP ratio, status và sphere modifier.
- UI hiển thị chance/quality theo rule thực; RNG có seed/log phục vụ test.
- U1.7a resolve một injected roll trước animation; sleep/back-strike được snapshot trước state transition và result chứa chance/tags cho presentation.
- U1.7b ưu tiên sphere Giga → Mega → Basic, chỉ trừ một item sau khi projectile đã validate; miss trả drop cùng stable item ID.
- Success tạo PetInstance và cập nhật roster trước khi wild node biến mất. Party đầy chuyển về storage/base theo policy tương lai.
- Acceptance: roll biên 0/1 xác định; thất bại không duplicate sphere/reward; save/load giữ captured pet.

### G06 — pet party và command

- Mỗi pet có persistent unique ID; active slot tham chiếu ID, không tham chiếu Node trong save.
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
- Acceptance: không overlap vùng cấm; reload giữ transform/state; dismantle trả đúng bảng refund.

### G12 — progression và quests

- EXP/unlock nhận event domain; objective không scan world liên tục.
- QuestDefinition dùng objective IDs/counts và reward transaction. Claim một lần.
- Base level mở capacity/building/biome rõ; không chỉ tăng số mà thiếu lựa chọn.
- Acceptance: event trước khi nhận quest theo policy đã định; save/load không claim lại; content thiếu ID báo lỗi validator.

### G13 — time, raid và boss

- WorldClock là nguồn thời gian duy nhất cho day/night/schedule; pause policy rõ.
- EncounterDirector dùng budget/condition/cooldown, không spawn boss chỉ bằng timer hardcode.
- Raid telegraph, preparation window, win/lose condition và reward rõ.
- Acceptance: không spawn trùng khi reload; raid ngoài loaded chunk có policy; boss defeat persist.

### G14 — world rộng

- Chunk load quanh player theo radius và budget; persistent delta ghi resource/crop/building/spawn changes.
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
- Acceptance: save → quit → load giữ inventory, roster, assignment, building, crop, quest và world clock; corrupt file trả lỗi an toàn.

## Thứ tự ưu tiên playable vertical slice

1. Data IDs + inventory transaction.
2. Một creature definition xuyên suốt combat → capture → roster → summon.
3. Một farm plot + một job pet → output vào chest.
4. Một building placement + một processing recipe.
5. Save/load cho toàn slice.
6. Sau khi slice ổn định mới nhân content, mở world và nâng UI/art.
