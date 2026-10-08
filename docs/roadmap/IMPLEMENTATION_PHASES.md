# Work packages và gate triển khai

Mỗi package kéo dài khoảng 0,5–2 ngày, giữ game chạy được và có checkpoint riêng. Không chạy hai migration lớn trên cùng một god script trong một package.

## U0 — baseline và governance

| Package | Deliverable | Gate | Trạng thái |
|---|---|---|---|
| U0.1 | Sửa parse, audio lifecycle, headless editor/smoke | `tools/check_project.ps1` xanh | VERIFIED |
| U0.2 | Asset manifest/hash/reference/duplicate + docs hệ thống | Validator manifest và Godot gate xanh | VERIFIED |
| U0.3 | Git repository/snapshot/tag | Có restore test; `.godot` không tracked | VERIFIED |
| U0.4 | Quarantine mapping và replacement priority | Mọi runtime asset có owner/action | VERIFIED |

U0 chỉ hoàn tất khi baseline có thể khôi phục và asset mới không đi vào runtime nếu thiếu receipt/license.

## U1 — data và ranh giới domain

1. **U1.1 Core IDs/registry — VERIFIED:** `ContentId`, definition base/item canary, registry và validator. Generic result types được hoãn tới package domain đầu tiên để tránh abstraction chưa có consumer.
2. **U1.2 Wood pickup/inventory adapter — VERIFIED:** `item.wood` chạy xuyên ResourceNode → drop → Player stable API; dictionary `Gỗ` vẫn là nguồn sự thật để giữ consumer cũ.
3. **U1.3 Recipe/Building/Crop definitions — VERIFIED:** typed canary sphere/workbench/berry và deterministic missing-reference validation; runtime giữ adapter/dictionary/enum cũ.
4. **U1.4 Inventory transaction — VERIFIED:** pure transaction/Player/drop; chest finite capacity + atomic mapped batch. Direct writers khác migrate theo domain package.
5. **U1.5 Combat result — VERIFIED:** pure deterministic resolver; migrate Player + WildCreature, giữ caller adapter.
6. **U1.6 Player components — VERIFIED:** needs, locomotion và stable action input boundary có pure regression; Player còn làm coordinator/presentation adapter. Build/craft/progression tiếp tục theo domain package, không quay lại gom vào Player.
7. **U1.7 Capture service — VERIFIED:** U1.7a deterministic result, U1.7b stable sphere transaction và U1.7c atomic roster ownership có regression; persistent PetInstance/save thuộc U1.10–U1.11.
8. **U1.8 Creature perception/FSM — VERIFIED:** U1.8a perception cadence, U1.8b core transition và U1.8c basic lifecycle closure có pure/actor regression; skill/ecology writer đã phân loại sang U1.9.
9. **U1.9 Creature skills/drop — VERIFIED:** U1.9a–u gồm typed species, toàn bộ species attack tuning, deterministic defeat drops và burn tick qua combat boundary.
10. **U1.10 Pet roster/command — VERIFIED:** U1.10a–d khóa persistent identity, single-node summon và deterministic cycle/explicit stance commands; target/job depth thuộc U5.
11. **U1.11 Save v1 foundation — VERIFIED:** U1.11a–f gồm schema, runtime snapshot/apply, atomic repository, migration harness và explicit coordinator. Autosave/UI/world-base coverage thuộc package sau; gate U1 tổng thể chưa đạt.
12. **U1.12 Persistence coverage — VERIFIED:** U1.12a–ak đóng explicit Save v1 cho vertical slice/world tĩnh; không còn gap HIGH/CRITICAL. Ambient wild population hoãn tới U2 chunk identity, autosave/slot UI thuộc U3.
13. **U1.13 Boundary closure — VERIFIED:** U1.13a baseline; U1.13b chuyển Player craft sang typed stable catalog/pure resolver/atomic transaction; U1.13c chuyển 19 Creature FSM decision bypass vào transition policy/apply owner, writer surface 29 → 10 và không còn direct decision bypass.

Gate U1: **VERIFIED 2026-10-08**. Vertical slice combat → capture → pet → farm/build → save/load dùng ID/data typed; persistence đạt qua U1.12ak, Player craft boundary qua U1.13b và Creature FSM ownership qua U1.13c. Validator, editor load và smoke xanh; manual feel review vẫn là kiểm chứng bổ sung, không phải blocker gate kiến trúc.

## U2 — world rộng

1. **Biome/ChunkDefinition và coordinate contract — VERIFIED:** typed canary, signed runtime key, catalog/context và Main read adapter; chưa stream/persist chunk.
2. **Chunk admission/unload — VERIFIED:** pure 3×3 policy, revision guard, admit-before-unload placeholder scenes, exact-nine ownership và toggleable debug overlay; U2.9 đã migrate static decorations vào chunk lifecycle (manifest deterministic, unload free cả cây, không leak).
3. **Persistent world delta foundation — VERIFIED:** building/resource records có typed chunk envelope và Save v1 fallback; crop nằm trong building record, captured/ambient spawn chờ spawn identity.
4. **Navigation theo chunk — VERIFIED foundation:** typed request/result, exact region ownership, revision-guarded whole-region obstacle state và RID cleanup; terrain bake/path requests còn chờ content package.
5. **Spawn director — VERIFIED foundation + persistent cooldown + authored biome tables:** deterministic active-chunk/biome/time/budget policy, stable ambient slot identity và runtime registry tách boss/raid; defeat/capture đăng ký cooldown 120s theo world clock qua `AmbientCooldownState`, slot cooling-down không refill, persist Save v1 (`world.ambient_cooldowns`) với legacy fallback; species/level/slot budget do `BiomeSpawnTable` data-driven (biome lạ fallback meadow + warning), tái tạo bit-for-bit công thức legacy.
6. **Discovery/fog — VERIFIED data + persistence + fast travel domain + minimap UI:** center-entry state, revision guard, detached tile snapshot và Save v1 round-trip; fast travel chỉ tới discovered chunk với stable ID, cost, cooldown, encounter guard và atomic commit; minimap/fog renderer và destination picker là presentation read-only phát intent; fog-of-war art nâng cao còn chờ package art.

Gate U2: qua 9 chunk không mất state; soak 20 phút; không hitch vượt budget đã chốt; save/load ở chunk khác hoạt động.

## U3 — UI/UX

1. **UI tokens + Theme — VERIFIED foundation:** `PaloriaTheme` design tokens (palette, type scale, radii, spacing) + stylebox factories; code-built UI (recipe/cooking cards, minimap panel) dùng tokens; inline sub-resources trong hud.tscn là legacy, migrate khi rebuild panel.
2. **HUD ViewModel — VERIFIED:** `HUDViewModel.from_player()` là nơi duy nhất đọc player state; `hud.render_view_model()` render snapshot; quest panel giữ push path tới U3.2.
3. **Inventory/crafting/build/pet roster screens; save/load slot UI và autosave controls — VERIFIED (U3.2/U3.3):** crafting/cooking modals render từ typed ViewModel với intent-only buttons; SaveSlotManager (slot_1..3 + autosave, metadata, delete) và slot panel (F9) + F5 quicksave; autosave opt-in, mặc định TẮT, interval 5 phút, chỉ chạy khi không modal/encounter.
4. **Context prompt — VERIFIED (U3.4):** `player.get_interaction_target()` (nearest interactable, tách từ try_interact); `ContextPrompt` label nổi gần target theo world→screen, text từ localization key `prompt.interact_hint` + tên target (`interaction_prompt_name()`); ẩn khi modal mở; update 10Hz trong Main.
5. **Settings — VERIFIED (U3.4):** `GameSettings` static (master volume, UI scale 0.75–1.5, reduce motion, locale, input remap) lưu `user://settings.cfg` tách khỏi save game; settings panel (F10) phát intent, Main apply + persist; remap cơ bản (tương tác/né/ném cầu) qua `PlayerActionInputMapper.action_key`; volume → AudioServer Master bus; UI scale → HUD transform quanh tâm màn hình; reduce motion gate `player.shake_camera`.
6. **Localization keys và Vietnamese/English baseline — VERIFIED (U3.4):** `Localization` static đọc `assets/i18n/<locale>.csv` (key,text), fallback en rồi tới key; text mới (settings, slots, prompt) qua keys; inventory/save giữ stable ID; string legacy còn hardcode sẽ migrate dần.

Gate U3: thao tác core loop bằng keyboard/gamepad; focus/pause đúng; 720p–1440p; UI không mutate domain.

## U4 — art, animation và feedback

1. Asset license gate + art bible + import presets.
2. Player locomotion/combat AnimationTree và marker.
3. Một pet hoàn chỉnh idle/move/work/attack/hurt/down.
4. Creature telegraph + elemental VFX + hit feedback.
5. Tile/prop normalization và biome pass.
6. Audio event map, mix buses và accessibility multipliers.

Gate U4: asset runtime đều VERIFIED hoặc original; animation không điều khiển kết quả domain; frame pacing và visual review đạt checklist.

## Featured initiative AT — town/art/audio renewal

Sáng kiến AT không chen vào U1. Nó bắt đầu sau khi U2.1–U2.3 chốt chunk identity, streaming và persistent delta:

1. AT0 art direction/reference board nguyên bản.
2. AT1 greybox ga → phố dốc → đền trên 3×3 chunk.
3. AT2 một package terrain/prop được admit và normalize.
4. AT3 day/dusk/night/rain lighting-weather pass.
5. AT4 thay player và một pet hero đủ animation coverage.
6. AT5 MusicContext/AudioDirector và town ambience.
7. AT6 mở rộng từng quận; AT7 polish/cinematic/accessibility.

Không dùng asset hoặc soundtrack từ “Your Name”; tên phim chỉ mô tả mood người dùng mong muốn. Gate chi tiết ở docs/roadmap/ANIME_TOWN_RENEWAL.md.
## U5 — chiều sâu gameplay

1. Skill loadout, element/status và encounter roles.
2. Job board/reservation/suitability/needs cho pet.
3. Farming chain: soil → seed → water → harvest → processing.
4. Processing queues và logistics/storage.
5. Building tiers, repair/dismantle/defense.
6. Base progression, quest objectives, raids và bosses.
7. Economy/balance telemetry và content expansion.

Gate U5: vòng 30–45 phút có mục tiêu, lựa chọn pet/base đáng kể, không deadlock automation và không exploit duplicate resource đã biết.

## U6 — hardening và release

1. Save migration/corruption recovery và multi-slot UX.
2. Performance scenario + budgets + bounded optimization.
3. Soak/regression/accessibility matrix.
4. Asset/license/credits audit và export profiles.
5. Tutorial/onboarding, balance pass và release checklist.

Multiplayer chỉ được thiết kế sau U6 khi ownership, command/result và save state đã ổn định; không retrofit networking vào Node state hiện tại.

## Checklist bắt buộc cho mọi package

- Scope, invariant và out-of-scope được ghi trước.
- Code/data/docs cùng thay đổi; module và feature catalog được cập nhật nếu contract đổi.
- Có lệnh test, output thật và log path.
- Ghi save compatibility, asset provenance và migration/rollback.
- `docs/CHECKPOINT.md` trỏ đúng package kế tiếp và blocker.
