# Checkpoint triển khai Paloria 3.0

## U2.1 — chunk identity foundation

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và kết quả

- Thêm typed `BiomeDefinition`/`ChunkDefinition` và canary `biome.paloria_meadow` → `chunk.paloria_origin` qua content registry.
- Khóa chunk size 1024×1024, floor division đúng ở tọa độ âm và runtime key canonical `chunk.pN.nN`; definition ID và coordinate key là hai vai trò riêng.
- Thêm pure catalog/context và `Main.get_world_chunk_context()` read-only; không mutate SceneTree, spawn, streaming hoặc Save.
- Save/data breaking change: none. Gameplay/scene/asset/provenance: none.

### Validation và bàn giao

- Baseline full gate: pass, 46 Markdown files và toàn bộ checks xanh.
- Focused editor-load, content registry và world-chunk regression: pass; phủ boundary, signed-key round-trip/rejection, canary reference và Main adapter.
- Full gate cuối và strict scan: ghi tại `build/checks`; package chỉ VERIFIED khi cả hai sạch.
- Package kế tiếp: U2.2 admission foundation 3×3 + deterministic delta + debug snapshot theo `NEXT_UPDATE_PROMPT.md`.

## U1.13c — Creature FSM writer closure

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và kết quả

- Audit đủ 29 lexical writer site theo source, không dùng regex làm kết luận ownership.
- Chuyển 19 decision bypass (charge, attack/recovery, assist, retaliation, low-health flee, capture entry) vào pure `CreatureTransitionPolicy` và guarded apply owner.
- Writer surface còn 10 site hợp lệ: actor clock 1, locomotion direction 3, ecology prey adapter 2 và canonical state/timer/target commit 4; không còn direct FSM decision bypass.
- `scripts/creature.gd` 1.523 → 1.543 dòng do stable mapping/adapter; 67 hàm/55 field không đổi. Gameplay timing/balance, Save/data shape và asset: không đổi.

### Validation và bàn giao

- Baseline full gate trước thay đổi: pass, 46 Markdown files và toàn bộ Godot checks xanh.
- Focused editor load, `validate_creature_perception.gd` và `validate_creature_ecology.gd`: pass; regression mở rộng phủ charge chain, attack/recovery, flee, target SET, capture và stale recovery.
- Full gate cuối: pass (`check_project.ps1`, 46 Markdown files, toàn bộ validator, editor load và main-scene smoke). Strict scan `build/checks` không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path, leak hoặc `ERROR:`.
- Gate U1 đóng `VERIFIED`; package tiếp theo U2.1 chunk identity foundation theo `NEXT_UPDATE_PROMPT.md`, với cỡ package vừa gồm contract + adapter + regression + docs.

## U1.13b — Player craft transaction boundary

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và kết quả

- Chuyển 17 runtime recipe khỏi Player sang typed `PlayerCraftDefinition`/catalog với stable recipe/item/equipment/building IDs.
- Pure resolver từ chối unknown/locked/insufficient; shadow transaction bảo đảm input/output item atomic kể cả source đổi sau resolve.
- Player chỉ commit accepted equipment/build-mode result và presentation; HUD phát stable recipe ID, legacy short ID chỉ còn compatibility input.
- Balance, unlock level, card order, localized presentation, audio, quest callback và build behavior giữ nguyên. Save v1/data breaking change: none.
- Re-measure: Player 1.262 → 1.081 dòng; direct inventory writer 14 → 8, craft path 6 → 0.

### Validation và bàn giao

- Baseline full gate trước thay đổi: pass, 45 Markdown files và toàn bộ Godot checks xanh.
- Focused `validate_item_migration.gd`: pass; phủ 17 definition, identity, rejection/no-mutation, atomic conservation/stale source, building result và live Player gear adapter.
- Asset/provenance: none. Rollback: bỏ `systems/crafting`, trả catalog/handler legacy vào Player và bỏ regression/docs U1.13b.
- Full gate sau thay đổi: pass (`check_project.ps1`, 46 Markdown files, toàn bộ validator gồm craft regression, editor load và main-scene smoke); strict scan log không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path, leak hoặc `ERROR:`.
- Gate U1 chưa đóng; gói kế tiếp U1.13c audit 29 Creature FSM writer site.

## U1.13a — Player/Creature boundary measurement

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và kết quả

- Lập baseline lexical tái lập được, không đổi runtime: Player 1.262 dòng/46 hàm/49 field; Creature 1.523/67/55.
- Ghi rõ lexical writer inventory không phải AST và không thấy alias/property/method side effects; repository hiện không có ref `baseline-u0.3` nên chưa có historical trend đáng tin cậy.
- Player craft là extraction đầu tiên: catalog khoảng 155 dòng, handler khoảng 61 dòng, sáu site inventory mutation cùng gear/build decision vẫn nằm trong actor.
- Creature còn 29 FSM/target writer site lexical; chưa chọn extraction theo line count, sẽ audit sau craft boundary.

### Validation, compatibility và bàn giao

- Baseline full gate trước thay đổi: pass; 44 Markdown files, toàn bộ validator, editor load và main-scene smoke xanh.
- Save/data breaking change: none. Gameplay/API change: none. Asset/provenance: none.
- File tài liệu mới: `docs/architecture/BOUNDARY_METRICS.md`; đồng thời sửa hai dòng workbench persistence cũ đã lỗi thời.
- Full gate sau thay đổi: pass (`check_project.ps1`, 45 Markdown files, toàn bộ validator, editor load và main-scene smoke); strict scan log không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path, leak hoặc `ERROR:`.
- Rollback: revert tài liệu U1.13a; runtime không đổi. Gói kế tiếp: U1.13b Player craft transaction boundary.

## U1.12ak — persistence closure audit

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và kết quả

- Re-audit owner/runtime với Save v1 schema/snapshot/apply và regression; không sửa code, schema hoặc gameplay.
- Không còn gap persistence `HIGH`, `CRITICAL` hoặc `BLOCKER` trong vertical slice/world tĩnh; U1.12 được đóng `VERIFIED`.
- Ambient wild population giữ `MEDIUM/NONE` và route sang U2 chunk/spawn identity; autosave/slot UI route sang U3, hardening multi-slot cuối thuộc U6.
- Transient input/build preview, cooldown, animation/VFX, target/tween và capture transaction chưa commit không bị ghi sai thành persistent state.

### Validation, compatibility và bàn giao

- Baseline full gate trước thay đổi: pass; 44 Markdown files, toàn bộ validator, editor load và main-scene smoke xanh.
- Source metric tại audit: `scripts/player.gd` 1.262 dòng, `scripts/creature.gd` 1.523 dòng; craft/build handler vẫn authoritative trong Player.
- Save/data breaking change: none. Asset/provenance: none. Rollback: revert bốn tài liệu U1.12ak.
- Gate U1 tổng thể chưa đóng: cần U1.13a đo ownership/writer surface và xác định extraction nhỏ cần thiết.
- Full gate sau thay đổi: pass (`check_project.ps1`, 44 Markdown files, toàn bộ validator, editor load và main-scene smoke); strict scan log không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path, leak hoặc `ERROR:`.
- Gói kế tiếp: U1.13a boundary measurement theo `NEXT_UPDATE_PROMPT.md`.

## U1.12aj — Player progression Save v1 admission

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và kết quả

- Admit typed progression state vào `player.progression_state`; snapshot fail closed với runtime gear/state không map hoặc incoherent.
- Apply resolve trước mutation, derive weapon name/damage/armor bool từ stable ID và commit stat/maxima/buff cùng Player scalar.
- Save v1 cũ thiếu field dùng zero allocation + toàn bộ unspent budget, starter gear/default maxima và no buff; current scalar clamp vào maxima.
- Scene regression phủ Pal snapshot, iron apply, allocated stats, active/no buff, JSON compatibility, legacy fallback và invalid no-mutation.

### Validation, compatibility và bàn giao

- Baseline full gate trước thay đổi: pass.
- Focused `validate_save_schema.gd` và `validate_save_coordinator.gd`: pass; fixture-order regression đã sửa bằng cách chạy legacy case sau subtype assertions.
- Full gate: pass (`check_project.ps1`, 44 Markdown files, toàn bộ validator, editor load và main-scene smoke); strict scan log không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path, leak hoặc `ERROR:`.
- Shape Save v1 pre-release đổi nhưng version giữ 1; legacy field missing có fallback. Asset/provenance: none.
- Rollback: bỏ nested field/projection/apply plan và U1.12aj regression/docs; pure U1.12ai vẫn giữ.
- Gói kế tiếp: U1.12ak persistence closure audit theo `NEXT_UPDATE_PROMPT.md`.

## U1.12ai — Player progression persistence contract

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Tạo pure typed contract trước Save admission; không đổi runtime Player/gameplay/Save v1.
- Khóa deterministic EXP threshold, budget hai điểm mỗi level, derived max HP/stamina, needs maxima và stable equipment/buff IDs.
- Không dùng localized weapon name, crafting short ID, asset path hoặc derived damage làm identity.

### Kết quả triển khai

- `PlayerProgressionState` validate/JSON-project toàn bộ progression metadata và legacy default bảo thủ.
- `PlayerEquipmentCatalog` allow ba weapon/hai armor ID, derive damage và armor HP bonus hiện hữu.
- Focused regression phủ JSON integer normalization, budget/threshold/range/maxima/ID/buff guard và legacy fallback.
- Save/data breaking change: none; state chưa admit vào Save v1. Asset/provenance: none.

### Validation và bàn giao

- Baseline full gate trước thay đổi: pass.
- Focused `validate_player_progression.gd`: pass sau khi khóa JSON float-integer normalization.
- Full `tools/check_project.ps1` bằng Godot 4.7.2: pass; 44 Markdown files, editor load, focused progression và toàn bộ gameplay/save/world validators + smoke xanh.
- Strict scan `build/checks`: không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path, `RID leaks`, `ObjectDB instances leaked` hoặc `ERROR:`.
- Rollback: bỏ hai pure class, validator/check hook và docs U1.12ai; runtime/save không đổi.
- Gói kế tiếp: U1.12aj Save v1 snapshot/apply admission theo `NEXT_UPDATE_PROMPT.md`.

## U1.12ah — persistence coverage re-audit

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và kết quả

- Re-audit ma trận owner/state/identity sau U1.12ag, không đổi code/schema/gameplay.
- Xác nhận building/farm/static resource/world-boss/night-raid đã FULL trong phạm vi world tĩnh hiện tại; ambient wild population phụ thuộc U2 chunk policy.
- Chọn gap HIGH kế tiếp bằng source evidence: Player `max_exp`, stat budget/allocation, gear và needs maxima/buff chưa thuộc Save v1, có thể reset không nhất quán với level/EXP đã restore.

### Validation và compatibility

- Full `tools/check_project.ps1` bằng Godot 4.7.2: pass; 43 Markdown files, asset/content/editor-load, toàn bộ gameplay/save/world/raid validators và main smoke xanh.
- Strict scan `build/checks`: không có `SCRIPT ERROR`, `Parse Error`, missing dependency, invalid node path, `RID leaks`, `ObjectDB instances leaked` hoặc `ERROR:`. Các hit chuỗi `RID/ObjectDB` ban đầu chỉ là substring trong tên asset `test_bridge.png`.
- Save/data breaking change: none. Asset/provenance: none. Rollback: revert thay đổi audit/roadmap/checkpoint/prompt.
- Gói kế tiếp: U1.12ai typed Player progression persistence contract theo `NEXT_UPDATE_PROMPT.md`.

## U1.12ag — night-raid Save v1 admission

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- ACTIVE round-trip exact remaining slot/species/level/HP/position, không reroll hoặc replay banner/reward/drop.
- CLEARED/PENDING không spawn; clock/guard/cycle incoherent fail trước mutation raid.
- Save v1 cũ thiếu field suy ra bảo thủ PENDING/CLEARED, không tự tạo encounter.

### Kết quả đã triển khai

- Thêm `world.night_raid_state` vào schema, snapshot, apply plan/result và coordinator result.
- Main project live owned roster khi save và restore actor từ stable species/slot với presentation suppression; terminal state dọn actor và không spawn.
- Regression thêm JSON/schema legacy/incoherence, ACTIVE/CLEARED scene round-trip, no reward/drop và corrupt repository preservation.
- Cập nhật contract Save/night raid, module, gameplay, roadmap và coverage audit. Save shape vẫn v1 pre-release; asset/provenance: none.

### Validation hiện tại

- `git diff --check`: pass (chỉ cảnh báo line-ending LF→CRLF của Git trên Windows).
- Full `tools/check_project.ps1 -GodotConsole C:\Users\User\Desktop\work_space\workaround\Godot_v4.7.2-stable_win64_console.exe`: pass; save schema/coordinator và night-raid focused regression xanh.
- Strict error/leak scan `build/checks`: sạch; editor load và main smoke xanh.

### Compatibility, rollback và gói tiếp theo

- Backward compatibility: missing `night_raid_state` + guard false → PENDING; guard true → CLEARED đúng cycle. Explicit malformed/incoherent DTO fail closed.
- Rollback: bỏ field/adapters/Main restore và regression U1.12ag; U1.12af runtime ownership vẫn giữ.
- Bước tiếp theo đã thực hiện: U1.12ah coverage re-audit.

## U1.12af — night-raid actor ownership và removal aggregation

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Main sở hữu đúng ba stable raid slot; duplicate trigger không tiêu thụ RNG hoặc tạo thêm actor.
- Chỉ đúng owned actor/slot/encounter được commit removal; foreign, sai reason và callback trùng fail closed.
- Partial roster giữ ACTIVE; roster rỗng chuyển CLEARED đúng một lần. Gameplay reward/drop/capture không đổi.

### Kết quả đã triển khai

- `trigger_night_raid(false)` hỗ trợ presentation suppression cho test/restore boundary, resolve toàn bộ spawn spec rồi publish ba actor có stable metadata/group và ACTIVE ledger.
- Main giữ `night_raid_actors`, nhận `defeated`/captured `removed` signal và tái tạo typed remaining roster sau mỗi commit hợp lệ.
- Morning reset không bỏ ownership của encounter ACTIVE; CLEARED/PENDING mới trở về canonical pending cycle.
- Regression scene thật phủ ba actor unique, duplicate trigger, foreign/duplicate callback, partial removal, unknown reason, capture + defeat aggregation và terminal CLEARED.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused `validate_night_raid_state.gd` xanh; fixture lifecycle có cleanup hai frame và log không còn RID/ObjectDB leak.
- Full `tools/check_project.ps1` xanh: 43 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save/world/raid validators; leak/error scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; `NightRaidState` chưa được admit vào Save v1.
- Asset/provenance: none.
- Restore active/cleared raid và chunk persistence chưa phủ.
- Rollback: bỏ Main ownership/callback, runtime regression và docs U1.12af; pure U1.12ae contract vẫn giữ.

### Gói tiếp theo

U1.12ag admit night-raid state vào Save v1 theo `NEXT_UPDATE_PROMPT.md`.

## U1.12ae — night-raid actor audit và typed contract

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Audit identity/lifecycle của ba night-raid actor trước Save admission.
- Contract phải phân biệt pending/active/cleared theo cycle và giữ resolved actor state.
- Không serialize Node, target, scene path hoặc species/angle/radius RNG; chưa spawn khi load.

### Kết quả đã triển khai

- Thêm `NightRaidState` với `raid.lifecycle.pending|active|cleared`, encounter `raid.night_current` và cycle index.
- Thêm ba slot `raid.night_actor_1..3` chứa resolved species, level 2–5, derived elite HP và finite position.
- Active giới hạn 1–3 actor unique; pending/cleared dùng canonical empty roster và guard/cycle coherence.
- Audit xác nhận Main chưa giữ actor reference/ID và chưa aggregate defeat/capture removal; Save v1 không đổi.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Focused editor-load/night-raid regression xanh: JSON round-trip, unique slot, spawn-species allowlist, HP maximum và cycle/guard coherence.
- Full `tools/check_project.ps1` xanh: 43 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save/world/raid validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; raid state chưa được nối Save v1.
- Asset/provenance: none.
- Raid actor ownership/removal, restore/reward suppression và chunk persistence chưa phủ.
- Rollback: xóa night-raid state/validator/gate và docs U1.12ae.

### Gói tiếp theo

U1.12af thiết lập raid actor ownership/removal theo `NEXT_UPDATE_PROMPT.md`.
