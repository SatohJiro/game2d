# Version control và restore point

## Repository

- Local repository: `D:\desktop\VS_WorkSpace\game2d\.git`
- Default branch: `main`
- Remote: chưa cấu hình; không có push/publish trong U0.3.
- Root baseline commit: `2c243e1` (`chore: establish verified Paloria baseline`).
- Stable restore tag: `baseline-u0.3` trỏ tới checkpoint đã có tài liệu U0.3.
- Commit baseline dùng identity cục bộ `Paloria Baseline <paloria@local.invalid>` vì máy chưa cấu hình global email. Identity này không thay đổi Git config của người dùng.

## Nội dung snapshot

Snapshot chứa source, scene, Godot sidecar `.import`/`.uid`, asset hiện hữu, tools và docs. Nó không chứa `.godot/`, `build/`, log, export hoặc package/cache directory theo `.gitignore`.

Asset trong commit vẫn có trạng thái license `QUARANTINE/UNKNOWN`; việc Git theo dõi file không xác nhận quyền phân phối.

## Quy trình an toàn trước work package

```powershell
git status --short
git switch -c work/<package-id>-<short-name>
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_project.ps1
```

Không bắt đầu package khi working tree có thay đổi không thuộc package mà chưa ghi vào checkpoint.

## Phục hồi không phá hủy công việc hiện tại

Khôi phục một file vào đường dẫn khác để so sánh:

```powershell
git show baseline-u0.3:scripts/player.gd > $env:TEMP\player.baseline.gd
```

Khôi phục file đã chọn sau khi đã lưu thay đổi cần giữ:

```powershell
git restore --source baseline-u0.3 -- scripts/player.gd
```

Kiểm tra toàn snapshot trong worktree riêng:

```powershell
git worktree add --detach build/restore-check baseline-u0.3
powershell -NoProfile -ExecutionPolicy Bypass -File build/restore-check/tools/check_project.ps1 -ProjectPath build/restore-check
git worktree remove build/restore-check
```

Không dùng `git reset --hard` làm hướng dẫn phục hồi mặc định. Nếu cần quay toàn bộ project, tạo branch bảo toàn trạng thái hiện tại trước.

## Commit convention

- `feat:` gameplay/module mới.
- `fix:` sửa behavior hoặc regression.
- `refactor:` đổi cấu trúc không đổi behavior chủ ý.
- `data:` content/definition/balance.
- `assets:` vendoring/derivative/provenance.
- `docs:` tài liệu/ADR/checkpoint.
- `test:` gate/harness/scenario.
- `chore:` toolchain/repository maintenance.

Mỗi commit/package phải trỏ được tới checkpoint hoặc work package ID và không trộn migration không liên quan.

