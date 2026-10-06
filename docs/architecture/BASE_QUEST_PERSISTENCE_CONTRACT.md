# U1.12d — Base và quest persistence contract

## Mục tiêu và invariant

Base progression phải round-trip mà không dùng localized title hoặc array index làm save identity, và quest đã nhận thưởng không thể claim lại sau load. Package giữ nguyên objective, reward EXP, unlock level và UI text; building/crop/world delta không thuộc phạm vi.

## Stable identity và typed state

`BaseQuestCatalog` định nghĩa thứ tự nội dung hiện hữu bằng năm ID:

- `quest.base.survival`
- `quest.base.organic_farming`
- `quest.base.automation`
- `quest.base.fortress`
- `quest.base.paloria_lord`

`BaseProgressState` chứa `base_level`, `active_quest_id`, `claimed_quest_ids`. State chỉ hợp lệ khi claimed IDs là prefix liên tục của catalog, active ID là quest kế tiếp (hoặc rỗng sau quest cuối), và base level khớp unlock level của reward cuối đã claim. Nhờ đó save không thể skip quest, hạ level hoặc tạo tổ hợp claim mâu thuẫn.

## Runtime và save flow

- `BaseManager.pet_party` không liên quan; `BaseManager.claimed_quest_ids` là ledger chống reward lặp trong runtime.
- `advance_quest()` kiểm tra stable quest ID chưa claim trước mọi mutation, sau đó ghi ledger trước EXP/unlock presentation.
- `create_persistence_state()` và `apply_persistence_state()` là boundary typed; apply không phát reward hoặc tự chạy objective.
- Save v1 có DTO `base`; snapshot lấy state từ `player.base_manager_ref`, apply resolve/validate state trước commit. Player scene độc lập không có owner dùng default pristine state; non-default state mà thiếu owner fail closed.

Save v1 shape đổi nhưng version giữ 1 vì chưa có save phát hành. Snapshot cũ thiếu `base` fail validation; sau release, thay đổi shape phải tăng version và có migration. Asset/provenance: none.

## Validation và rollback

`tools/validate_base_progression.gd` khóa catalog, DTO round-trip, prefix/level/active invariants và duplicate reward guard. `tools/validate_save_schema.gd` khóa localized identity rejection cùng snapshot/apply atomicity. Rollback cần revert catalog/state, BaseManager ledger, Save DTO/adapters, validator và tài liệu U1.12d.
