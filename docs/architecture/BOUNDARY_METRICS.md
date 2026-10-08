# U1.13a — Player/Creature boundary metrics

Ngày đo: 2026-10-08. Đây là baseline lexical tái lập được cho gate U1; package không đổi gameplay, runtime API hoặc Save v1.

## Phương pháp và giới hạn

Chạy từ project root:

```powershell
$targets = @('scripts/player.gd', 'scripts/creature.gd')
foreach ($file in $targets) {
  $lines = Get-Content -Encoding UTF8 $file
  $functions = Select-String -Path $file -Pattern '^func '
  $fields = Select-String -Path $file -Pattern '^(?:@export )?var '
  [pscustomobject]@{ File=$file; Lines=$lines.Count; Functions=$functions.Count; TopLevelVars=$fields.Count }
}
```

Writer inventory dùng `Select-String` trên danh sách field đã biết, loại khai báo top-level và toán tử so sánh. Đây là lexical inventory, không phải GDScript AST: nó không phát hiện mutation qua alias, `set()`/`call()`, method side effect hoặc property setter; số site không đồng nghĩa số mutation runtime. Kết quả phải được review cạnh source trước khi chọn extraction.

Không có tag/ref `baseline-u0.3` trong repository hiện tại nên không thể dựng trend lịch sử đáng tin cậy. U1.13a là baseline đầu tiên; không dùng con số roadmap cũ thay bằng chứng Git.

## Baseline

| Actor adapter | Dòng | Hàm | Field top-level | Pure/boundary files đã tách |
|---|---:|---:|---:|---:|
| `scripts/player.gd` | 1.262 | 46 | 49 | 22 file dưới `systems/player` |
| `scripts/creature.gd` | 1.523 | 67 | 55 | 54 file dưới `systems/creature` |

Line count chỉ là cảnh báo kích thước, không phải gate độc lập. Gate quan trọng hơn là gameplay decision/writer đã nằm sau contract deterministic hay vẫn được actor script tự quyết định.

## Ownership và writer surface quan sát được

| Surface | Bằng chứng lexical/source | Đánh giá ownership |
|---|---|---|
| Player inventory | 14 site ghi trực tiếp; sáu site nằm trong `craft_recipe()` (một loop trừ nguyên liệu và năm output branch) | Inventory API đã có nhưng crafting còn bypass transaction owner |
| Player progression/gear | 21 site root-field theo lexical filter | Damage/EXP adapter phần lớn đã có contract; craft vẫn tự chọn gear result bằng short ID và localized fields |
| Player build/pet mode | Năm site scalar mode/active identity; placement/pet snapshot đã có typed boundary | Chủ yếu coordinator state; build placement policy vẫn là package U5, không phải extraction đầu tiên |
| Creature health/lifecycle | 11 site | Damage/drop/capture result đã deterministic; actor giữ commit và presentation hợp lệ |
| Creature FSM/target | 29 site ghi `state`, timer, target, prey hoặc wander direction | Transition policy đã phủ nhiều flow nhưng attack/pack/hunt compatibility còn ghi actor trực tiếp; cần audit riêng sau Player craft |
| Creature status timers | Tám site | Cadence/status presentation còn actor-owned; burn damage result đã qua combat boundary |

## Function/domain review

46 hàm Player phân thành: input/locomotion 5; presentation/lifecycle 6; progression/needs/combat 8; capture 7; craft/build/world persistence 9; pet/interaction 6; inventory facade 5. Việc Player làm coordinator không tự nó vi phạm gate, nhưng catalog recipe và quyết định craft result hiện nằm ngay trong actor.

Creature đã có pure definition, skill, perception, transition, ecology, drop và capture contracts. Kích thước còn lớn vì actor cùng giữ physics, animation, pack behavior, skill execution và compatibility FSM; vì vậy không được chọn extraction chỉ để giảm line count.

## Quyết định gate và package kế tiếp

U1 chưa đủ bằng chứng đóng gate. Extraction đầu tiên là U1.13b Player craft transaction boundary vì:

1. `recipes` legacy chiếm khoảng 155 dòng trong Player và trộn stable decision với localized text/asset path.
2. `craft_recipe()` khoảng 61 dòng, trực tiếp trừ/cộng inventory và tự commit gear/build outcome.
3. Scope có thể giữ nguyên HUD/audio/build-mode presentation: pure request/result resolve stable recipe/output, Player chỉ commit accepted result qua inventory/equipment/build adapters.

Acceptance U1.13b: runtime recipe identity dùng `recipe.*`; material/output item dùng `item.*`; insufficient input không mutate; accepted item craft atomic; gear result dùng `equipment.*`; building result trả stable `building.*`; Player không còn recipe catalog hoặc direct inventory writer trong craft path. Không mở queue/timing/logistics, balance hoặc UI redesign.

Sau U1.13b phải đo lại cùng baseline và audit 29 Creature FSM writer sites trước khi quyết định gate U1. Save/data breaking change: none. Asset/provenance: none.

## U1.13b re-measurement

Sau extraction, `scripts/player.gd` còn 1.081 dòng, 46 hàm, 49 field; giảm 181 dòng so với baseline U1.13a. Lexical direct inventory writer giảm 14 → 8 và craft path giảm 6 → 0. 17 definition cùng resolver/transaction chuyển sang `systems/crafting`; line count toàn dự án không phải mục tiêu, ownership và failure atomicity mới là bằng chứng gate.

Creature baseline không đổi: 1.523 dòng/67 hàm/55 field và 29 FSM/target writer site lexical. U1.13c phải phân loại từng site thành accepted commit, presentation/physics hoặc decision bypass trước khi chọn extraction; chưa đóng gate U1 tại U1.13b.

## U1.13c Creature FSM closure

Audit source của cả 29 site xác định 19 decision bypass thuộc charge, attack/recovery, low-health flee, pack assist, damage retaliation và capture entry. Các đường này nay resolve qua `CreatureTransitionPolicy` rồi commit bằng `apply_creature_transition()`; policy dùng stable event/state ID và giữ stale/protected guard.

Lexical writer còn lại giảm 29 → 10: một actor clock decrement, ba `wander_dir` locomotion writer, hai `prey_target` adapter writer chỉ chạy sau accepted ecology transition, và bốn assignment canonical trong apply owner (`state`, `state_timer`, target CLEAR/SET). Không còn FSM decision bypass trực tiếp. `scripts/creature.gd` là 1.543 dòng/67 hàm/55 field; tăng 20 dòng mapping/adapter là chấp nhận được vì gate đo ownership, không tối ưu line count mù.

Kết luận: Player craft writer đã đóng ở U1.13b, Creature FSM decision writer đã đóng ở U1.13c, persistence vertical slice đã đóng ở U1.12ak; gate U1 đủ bằng chứng để chuyển sang U2. Save/data breaking change và asset/provenance: none.
