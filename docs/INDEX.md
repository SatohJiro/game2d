# Paloria 3.0 — chỉ mục tài liệu

Tài liệu này là điểm vào bắt buộc cho người và AI agent. Trạng thái thực thi gần nhất nằm trong `CHECKPOINT.md`; roadmap không được dùng thay cho bằng chứng kiểm thử.

## Thứ tự đọc

1. `AGENTS.md`: quy tắc bắt buộc và lệnh kiểm tra.
2. `docs/CHECKPOINT.md`: work package gần nhất, thay đổi thật và phần còn lại.
3. `docs/roadmap/IMPLEMENTATION_PHASES.md`: thứ tự package và gate.
   Prompt package kế tiếp: `docs/NEXT_UPDATE_PROMPT.md`.
4. `docs/architecture/MODULES.md`: ownership, contract và ranh giới module.
5. `docs/architecture/DATA_CONTRACTS.md`: grammar ID, typed Resource, registry và migration legacy.
6. `docs/architecture/INVENTORY_MIGRATION.md`: boundary stable ID, adapter và single source of truth hiện tại.
7. `docs/architecture/INVENTORY_TRANSACTIONS.md`: transaction/result, capacity policy và direct-writer audit.
8. `docs/architecture/DOMAIN_DEFINITIONS.md`: schema recipe/building/crop, cross-reference và runtime boundary.
9. `docs/architecture/COMBAT_CONTRACT.md`: damage request/result, adapter và legacy caller audit.
10. `docs/architecture/CAPTURE_CONTRACT.md`: chance request/result, sphere transaction và Creature adapter.
11. `docs/architecture/CAPTURE_OWNERSHIP_CONTRACT.md`: stable species, rarity/trait và atomic roster ownership.
12. `docs/architecture/CREATURE_PERCEPTION_CONTRACT.md`: cadence, candidate policy, state guard và scan audit.
13. `docs/architecture/CREATURE_TRANSITION_CONTRACT.md`: stable transition reason, pure policy và apply boundary.
14. `docs/architecture/PLAYER_NEEDS_CONTRACT.md`: state, snapshot, buff ID và Player adapter của survival needs.
15. `docs/architecture/CREATURE_DEFINITION_CONTRACT.md`: typed Flam canary, legacy adapter và species field audit.
16. `docs/architecture/CREATURE_SKILL_CONTRACT.md`: stable skill ID, typed Flam fireball canary và remaining attack writer audit.
17. `docs/architecture/CREATURE_DROP_CONTRACT.md`: deterministic defeat drop, capture guard và atomic Flam commit.
18. `docs/architecture/CREATURE_ECOLOGY_CONTRACT.md`: pure damage-panic policy, stable ecology event và transition ownership.
19. `docs/architecture/PET_INSTANCE_CONTRACT.md`: unique pet identity, typed projection và capture-to-roster boundary.
20. `docs/architecture/SAVE_CONTRACT.md`: versioned Save v1 envelope, JSON-safe DTO và validation boundary.
21. `docs/architecture/PLAYER_LOCOMOTION_CONTRACT.md`: input snapshot, stamina/sprint/roll state và velocity precedence.
22. `docs/architecture/PLAYER_ACTION_CONTRACT.md`: stable action intent, physical mapping, guard và dispatch adapter.
23. `docs/gameplay/FEATURES.md`: luật chơi, invariant và acceptance criteria.
24. `docs/ASSET_PLAN.md` cùng `docs/assets/INVENTORY.md`: asset, license và quarantine.
25. `docs/roadmap/ANIME_TOWN_RENEWAL.md`: featured initiative town/world/art/audio xuyên U2–U4.
26. `docs/process/DOCUMENTATION_STANDARD.md`: tài liệu phải cập nhật khi sửa code/data/content.
27. `docs/process/VERSION_CONTROL.md`: branch, commit và phục hồi snapshot an toàn.

## Nguồn sự thật

| Chủ đề | Tài liệu chính | Khi nào phải cập nhật |
|---|---|---|
| Tiến độ hiện tại | `CHECKPOINT.md` | Sau mỗi work package |
| Phase, thứ tự, gate | `roadmap/IMPLEMENTATION_PHASES.md` | Khi scope hoặc dependency thay đổi |
| Kiến trúc và API module | `architecture/MODULES.md` | Khi tạo module, đổi ownership, signal hoặc data flow |
| Gameplay và cân bằng | `gameplay/FEATURES.md` | Khi luật chơi, input, reward hoặc failure state đổi |
| Asset | `ASSET_PLAN.md`, `assets/*` | Khi thêm, thay, xóa, đổi license hoặc derivative |
| Quyết định dài hạn | `decisions/ADR-*.md` | Trước thay đổi khó đảo ngược |
| Cách chạy | `README.md` | Khi toolchain, input hoặc launch flow đổi |

## Trạng thái tổng quan ngày 2026-10-04

| Hạng mục | Trạng thái | Bằng chứng / blocker |
|---|---|---|
| U0.1 baseline | Hoàn tất | Godot editor-load và main-scene smoke xanh |
| U0.2 asset inventory | Hoàn tất | Manifest/hash gate xanh; 166/166 asset chưa xác minh provenance |
| Git snapshot | Hoàn tất | Branch `main`, root commit `2c243e1`, tag `baseline-u0.3` |
| U0.4 asset triage | Hoàn tất | 166/166 có action; 69 runtime asset ở P0 |
| U1.1 content foundation | Hoàn tất | Stable ID, typed base/item definition, registry và headless validator |
| U1.2 wood inventory adapter | Hoàn tất | `item.wood` chạy qua drop/player API; legacy dictionary vẫn là nguồn sự thật |
| U1.3 domain definitions | Hoàn tất | 8 typed canary; field/domain/missing-reference validator và full gate xanh |
| U1.4a inventory transaction | Hoàn tất | Pure add/remove/transfer + Player/drop regression và full gate xanh |
| U1.4b chest capacity | Hoàn tất | Finite stack slots + atomic chest batch regression và full gate xanh |
| U1.5 combat result | Hoàn tất | Pure resolver + Player/Creature adapter regression và full gate xanh |
| U1.6a player needs | Hoàn tất | Pure needs state/snapshot + Player/HUD compatibility adapter và full gate xanh |
| U1.6b player locomotion | Hoàn tất | Typed input + pure stamina/sprint/roll/velocity result và full gate xanh |
| U1.6c player actions | Hoàn tất | Stable action intent + deterministic mapper/policy/dispatch regression |
| U1.7a capture result | Hoàn tất | Pure chance/result + injected roll, sleep bug regression và Creature adapter |
| U1.7b sphere transaction | Hoàn tất | Stable basic/mega/giga selection, atomic spend/launch và missed-drop adapter |
| U1.7c roster ownership | Hoàn tất | Stable species mapping, pure rarity/trait và atomic append/reward/despawn |
| U1.8a creature perception | Hoàn tất | Pure candidate policy, 0,20s cadence và protected-state group-scan guard |
| U1.8b creature transitions | Hoàn tất | 5 transition block qua pure policy/apply owner; async attack recovery có lifecycle guard |
| U1.8c creature lifecycle | Hoàn tất | Perception/natural/FLEE/capture restore qua apply owner; 10→0 writer block trong scope |
| U1.9a creature definition | Hoàn tất | `creature.flam` typed authority cho stats/behavior/drop; runtime adapter giữ compatibility |
| U1.9b creature skill | Hoàn tất | `skill.flam.fireball` typed authority cho attack tuning; actor adapter giữ timing/damage/lifecycle |
| U1.9c creature drop | Hoàn tất | Flam dùng deterministic drop result + atomic commit; quantity/capture compatibility giữ nguyên |
| U1.9d creature ecology | Hoàn tất | Damage panic dùng pure policy + transition owner; threshold/duration/RNG ordering giữ nguyên |
| U1.9e prey selection | Hoàn tất | Nearest deterministic candidate + lexical tie-break; capture/range/cadence compatibility giữ nguyên |
| U1.9f grazing decision | Hoàn tất | Injected roll + stable transition; strict 0.22 boundary và RNG short-circuit giữ nguyên |
| U1.9g hunt lifecycle | Hoàn tất | Abort/contact dùng stable transition; damage, boundary, recovery và stale guard được khóa regression |
| U1.9h predator threat | Hoàn tất | Panic callback dùng stable transition; target, FLEE 4 giây và lifecycle guards được khóa regression |
| U1.9i sleep decision | Hoàn tất | Injected roll + stable transition; strict 0.18 boundary, duration và RNG short-circuit được khóa regression |
| U1.9j drinking decision | Hoàn tất | Water/distance/roll snapshot + stable transition; boundary, duration, direction và RNG guard được khóa regression |
| U1.9k Slime definition | Hoàn tất | `creature.slime` typed stats/behavior authority; actor parity và legacy fallback được khóa regression |
| U1.9l Mushroom definition | Hoàn tất | `creature.mushroom` typed authority; berry-seed mapping, actor parity và Beast fallback được khóa regression |
| U1.9m Beast definition | Hoàn tất | `creature.beast` typed authority; fresh-meat mapping, predator parity và Dragon fallback được khóa regression |
| U1.9n Dragon definition | Hoàn tất | `creature.dragon` typed authority; Pal-ingot mapping và forced-elite parity được khóa regression |
| U1.9o Dragon fireball | Hoàn tất | `skill.dragon.fireball` có balance identity riêng; dispatch/tuning/stale recovery được khóa regression |
| U1.9p Mushroom spore | Hoàn tất | `skill.mushroom.spore` typed tuning; kiting/escape và projectile parity được giữ |
| U1.9q Slime hop | Hoàn tất | `HopSkillDefinition` typed movement/tween tuning; hop parity được khóa regression |
| U1.9r Beast charge | Hoàn tất | `ChargeSkillDefinition` typed range/timing/movement/stun; FSM ownership giữ nguyên |
| U1.9s melee boundary | Hoàn tất | Beast/Dragon melee có stable identity riêng; range/timing/lunge/contact parity được giữ |
| U1.9t remaining drops | Hoàn tất | Đủ năm species dùng deterministic typed drop result và atomic commit |
| U1.9u burn tick boundary | Hoàn tất | Burn damage dùng deterministic combat result; cadence, capture pause và presentation giữ nguyên |
| U1.10a PetInstance identity | Hoàn tất | Mỗi capture có unique `pet.*` ID và stable species ID qua typed projection |
| U1.10b summon lifecycle | Hoàn tất | Active selection theo instance ID; same-slot no-op và replace chỉ giữ một node trong tree |
| U1.10c pet command boundary | Hoàn tất | Stable cycle command và deterministic three-stance policy; invalid intent không mutate |
| U1.10d explicit pet commands | Hoàn tất | Direct work/combat/follow intents và idempotent no-change qua cùng policy |
| U1.11a Save v1 schema | Hoàn tất | Versioned JSON-safe envelope, stable-ID/reference/range validation và round-trip regression |
| U1.11b runtime snapshot | Hoàn tất | Player/inventory/pets → validated deep-copied DTO; unknown legacy key fail closed |
| U1.11c runtime apply | Hoàn tất | Validated plan resolve item/species/stance trước atomic Player commit; failure giữ source |
| U1.11d save repository | Hoàn tất | Temp verification + primary/backup rotation; corrupt primary đọc fallback không side effect |
| U1.11e migration harness | Hoàn tất | Deep-copy sequential registry; future/missing/cycle/ambiguous/invalid output fail closed |
| U1.11f save coordinator | Hoàn tất | Explicit primary/backup round-trip pipeline; stage failure không chạy partial apply |
| Kiến trúc data-driven | Chưa làm | Dictionary và logic còn tập trung trong god scripts |
| Save/load | Hạ tầng | Save v1 explicit Player round-trip xanh; chưa autosave/UI và chưa phủ world/base delta |
| World streaming | Chưa có | `main.tscn` vẫn là world tĩnh |
| UI system | Prototype | HUD lớn, style inline, chưa có Theme/accessibility settings |
| Asset admission mới | Bị chặn | `game-dev` CLI chưa có trong PATH |

## Quy ước trạng thái

- `PLANNED`: mới có đặc tả.
- `IMPLEMENTING`: code/data đang thay đổi, gate chưa đạt.
- `PLAYABLE`: chạy được trong vertical slice nhưng chưa đủ chất lượng phát hành.
- `VERIFIED`: acceptance criteria và test đã có bằng chứng.
- `BLOCKED`: có điều kiện ngoài package ngăn tiến độ, phải ghi rõ trong checkpoint.
- `QUARANTINE`: asset có thể giữ baseline local nhưng không đủ điều kiện phân phối.
