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
5. **U1.5 Combat result:** damage/status/faction contract; migrate player + một creature.
6. **U1.6 Player components:** input/locomotion/needs/build coordinator; giảm player từng phần.
7. **U1.7 Capture service:** deterministic request/result; roster state tách Node.
8. **U1.8 Creature perception/FSM:** không scan group mỗi frame.
9. **U1.9 Creature skills/drop:** definition-driven.
10. **U1.10 Pet roster/command:** persistent ID và summon lifecycle.
11. **U1.11 Save v1:** atomic save, DTO và migration harness.

Gate U1: vertical slice combat → capture → pet → farm/build → save/load dùng ID/data typed; validator và regression xanh; player/creature giảm trách nhiệm có đo lường.

## U2 — world rộng

1. Biome/ChunkDefinition và coordinate contract.
2. Chunk admission/unload quanh player với debug overlay.
3. Persistent world delta cho resource/crop/building/captured spawn.
4. Navigation theo chunk và obstacle update.
5. Spawn director theo biome/time/budget.
6. Discovery, minimap/fog và fast travel.

Gate U2: qua 9 chunk không mất state; soak 20 phút; không hitch vượt budget đã chốt; save/load ở chunk khác hoạt động.

## U3 — UI/UX

1. UI tokens + Theme + font/icon policy.
2. HUD ViewModel và intent bridge.
3. Inventory/crafting/build/pet roster screens.
4. Context prompt + device detection + command wheel.
5. Settings: remap, scale, audio, reduced motion/flash/shake.
6. Localization keys và Vietnamese/English baseline.

Gate U3: thao tác core loop bằng keyboard/gamepad; focus/pause đúng; 720p–1440p; UI không mutate domain.

## U4 — art, animation và feedback

1. Asset license gate + art bible + import presets.
2. Player locomotion/combat AnimationTree và marker.
3. Một pet hoàn chỉnh idle/move/work/attack/hurt/down.
4. Creature telegraph + elemental VFX + hit feedback.
5. Tile/prop normalization và biome pass.
6. Audio event map, mix buses và accessibility multipliers.

Gate U4: asset runtime đều VERIFIED hoặc original; animation không điều khiển kết quả domain; frame pacing và visual review đạt checklist.

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
