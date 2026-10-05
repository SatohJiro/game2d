# Prompt cho model tiếp theo — U1.9a CreatureDefinition audit

Tiếp tục Godot 4.7.2 project Paloria 3.0 bằng đúng một package nhỏ: U1.9a. Đọc `AGENTS.md`, `CHECKPOINT.md`, `DATA_CONTRACTS.md`, `CREATURE_TRANSITION_CONTRACT.md`, combat/capture contracts và roadmap trước khi sửa.

## Mục tiêu

Audit `species_data` legacy và tạo lát cắt typed `CreatureDefinition`/behavior profile nhỏ nhất cho một species canary, giữ runtime adapter tương thích. Không triển khai skill execution, drop resolver hoặc ecology refactor trong cùng package.

## Phạm vi bắt buộc

1. Chạy baseline gate; lập inventory field/consumer/writer của `species_data` và `species_index`.
2. Định nghĩa stable creature ID theo `DATA_CONTRACTS.md`; không dùng display name, texture path hoặc enum index làm identity.
3. Tạo typed resource canary và registry/reference validation cho đúng một species.
4. Thêm compatibility adapter để runtime hiện hữu đọc cùng giá trị stats/behavior mà không tạo store song song.
5. Không thay balance, asset, animation, collision, spawn, capture chance, skill hoặc drop behavior.
6. Regression cho valid/invalid definition, stable ID mapping, missing reference và runtime compatibility.
7. Cập nhật module/data/gameplay docs, checkpoint và writer metric.

## Definition of Done

- Pure/resource validator và actor compatibility regression xanh.
- Full `tools/check_project.ps1`, log scan và `git diff --check` sạch.
- Save/data compatibility, asset impact, rollback và manual gaps được ghi.

## Hướng sản phẩm phải bảo toàn

Typed definition phải hỗ trợ chunk unload/persistence U2. Không tải hoặc admit asset mới khi `game-dev` CLI còn thiếu; không dùng IP bên thứ ba làm content phát hành.
