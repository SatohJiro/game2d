# Checkpoint triển khai Paloria 3.0

## U1.9t — remaining creature defeat drops

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Route Slime/Mushroom/Beast/Dragon drops qua deterministic result và atomic commit.
- Giữ quantity, elite/alpha bonus, RNG ordering, capture/duplicate guards và presentation.
- Không đổi asset, save hoặc EXP reward.

### Kết quả đã triển khai

- `die()` dùng cùng request/resolver/commit cho đủ năm stable species.
- Xóa localized legacy drop spawn writer.
- Primary item lấy từ typed creature definition; bonus giữ `item.pal_ore`.

### Validation hiện tại

- Baseline full gate xanh.
- Focused resolver/actor regression xanh và teardown sạch leak.
- Khóa mapping Slime berry, Mushroom seed, Beast meat, Dragon Pal ingot cùng quantity/guard parity.
- Full final gate `tools/check_project.ps1` xanh; documentation, domain validators, editor load và main-scene smoke đều đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none. Asset/provenance: none.
- EXP reward và burn/status defeat writer chưa migrate.
- Rollback: revert U1.9t để khôi phục legacy branch; không cần migration.

### Gói tiếp theo

U1.9u audit và migrate burn tick damage/defeat path qua combat result boundary, giữ tick timing/damage/presentation. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
