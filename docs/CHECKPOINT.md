# Checkpoint triển khai Paloria 3.0

## U1.12a — persistence coverage audit

Trạng thái: `VERIFIED` ngày 2026-10-06.

### Mục tiêu và invariant

- Đối chiếu state runtime thực tế với stable identity, snapshot và apply coverage.
- Phân loại data-loss risk; không mở rộng schema hoặc sửa runtime trong audit.
- Chọn đúng một dependency ưu tiên cho package code kế tiếp.

### Kết quả đã triển khai

- Thêm `architecture/PERSISTENCE_COVERAGE_AUDIT.md` với ma trận Player/inventory/pet/base/building/crop/resource/world.
- Xác nhận core Player round-trip; pet metadata còn partial; base/building/crop/world delta chưa persist.
- Chọn inventory identity closure làm ưu tiên vì output gameplay chưa map làm toàn bộ snapshot fail `UNMAPPED_ITEM`.

### Validation hiện tại

- Full baseline gate xanh trước audit; không có code/scene/asset runtime thay đổi.
- Documentation check xanh: 26 required files, 39 Markdown files được quét.
- Full final gate `tools/check_project.ps1` xanh sau audit; toàn bộ gameplay/save validators giữ nguyên kết quả đạt.

### Compatibility, asset và giới hạn

- Save/data breaking change: none. Asset/provenance: none.
- Audit tĩnh chưa chứng minh từng loop bằng playthrough; package code kế tiếp phải thêm regression producer-group → snapshot.
- Rollback: revert tài liệu U1.12a; runtime U1.11 không đổi.

### Gói tiếp theo

U1.12b đóng tập stable identity cho inventory key runtime reachable và thêm coverage validator; không migrate backing dictionary/economy. Chi tiết ở `NEXT_UPDATE_PROMPT.md`.
