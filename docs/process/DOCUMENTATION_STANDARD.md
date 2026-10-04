# Tiêu chuẩn tài liệu và bàn giao

## Definition of Done

Một thay đổi chỉ hoàn tất khi code/data chạy đúng **và** tài liệu phản ánh trạng thái thật. Tối thiểu phải có:

1. Mục tiêu, phạm vi, invariant và phần không làm.
2. File/module/feature bị ảnh hưởng.
3. Public API, signal/event, data schema hoặc input/output đã đổi.
4. Save compatibility/migration; nếu không ảnh hưởng phải ghi `none`.
5. Asset mới/thay thế: source, author, license, hash, derivative recipe.
6. Test command, kết quả, giới hạn chưa kiểm chứng.
7. Rollback hoặc adapter giữ tương thích.
8. Checkpoint và package kế tiếp.

## Ma trận cập nhật

| Nếu thay đổi | Bắt buộc cập nhật |
|---|---|
| Trách nhiệm/API/signal module | `architecture/MODULES.md` |
| Content ID/definition/registry | `architecture/DATA_CONTRACTS.md` và ADR nếu rename/remove ID |
| Luật, reward, input, state gameplay | `gameplay/FEATURES.md` |
| Thứ tự/dependency/gate | `roadmap/IMPLEMENTATION_PHASES.md` |
| Asset file hoặc license | `assets/provenance_overrides.csv`, regenerate inventory, `ASSET_PLAN.md` |
| Save schema | module doc, feature G16, migration table và checkpoint |
| Input/UI flow | feature G01/G15, README controls nếu player-facing |
| Quyết định khó đảo ngược | ADR mới trong `docs/decisions` |
| Kết quả package | `CHECKPOINT.md` |

## Quy tắc viết

- Phân biệt `hiện trạng đã quan sát`, `mục tiêu`, `giả định` và `đã kiểm chứng`.
- Không ghi “hoàn tất phase” nếu gate chưa đạt. Không biến kế hoạch thành bằng chứng.
- Dùng ID/path/API cụ thể; tránh mô tả như “tối ưu”, “chuyên nghiệp”, “hoàn thiện” mà thiếu metric/criteria.
- Số cân bằng tạm phải ghi owner và nơi chuyển sang data Resource.
- Tài liệu chính viết tiếng Việt; identifier/API giữ tiếng Anh ổn định.

## ADR

Tạo ADR khi chọn storage format, world chunk identity, deterministic RNG, save migration policy, navigation strategy, asset license workflow hoặc thay đổi dependency direction. ADR có status `Proposed/Accepted/Superseded`, context, decision, consequence và migration.

## Bàn giao giữa model

Model mới bắt đầu bằng `docs/INDEX.md` và `CHECKPOINT.md`, chạy gate trước khi sửa. Khi dừng giữa package phải ghi rõ file đã sửa, test cuối, lỗi hiện tại và lệnh tiếp theo; không để trạng thái chỉ tồn tại trong hội thoại.

`tools/check_documentation.ps1` xác nhận bộ tài liệu bắt buộc và relative Markdown links. Script được gọi tự động bởi `tools/check_project.ps1`.
