# Checkpoint triển khai Paloria 3.0

## U1.12ad — world-boss capture lifecycle

Trạng thái: `VERIFIED` ngày 2026-10-08.

### Mục tiêu và invariant

- Accepted capture phải báo stable removal reason sau ownership commit nhưng trước actor free.
- Main chỉ terminal-commit đúng owned world boss; reject, duplicate, reason lạ và actor khác fail closed.
- Không đổi roster/reward capture; save sau capture không được respawn boss.

### Kết quả đã triển khai

- Creature thêm signal `removed(actor, encounter_instance_id, reason_id)` và stable reason `creature.removal.captured`.
- Signal chỉ phát sau `CaptureOwnershipResult.ACCEPTED`, trước success `queue_free()`; reject/duplicate không phát.
- Main route capture qua cùng terminal commit đã khóa reference/group/meta/ID như defeat.
- Save schema không đổi; captured terminal state dùng DEFEATED DTO hiện hữu.

### Validation hiện tại

- Baseline full gate xanh trước thay đổi.
- Baseline full gate xanh trước thay đổi.
- Focused capture/world-boss/coordinator regressions xanh: accepted phát đúng một reason; reject không phát; unknown/duplicate callback fail closed.
- Captured world boss save/load giữ terminal lifecycle và không spawn actor.
- Full `tools/check_project.ps1` xanh: 42 Markdown files, asset/content gates, editor load và toàn bộ gameplay/save/world-boss validators; leak-aware scan `build/checks` sạch.

### Compatibility, asset và giới hạn

- Save/data breaking change: none; dùng terminal DTO hiện hữu.
- Asset/provenance: none.
- Generic external despawn, raid actor và chunk persistence chưa phủ.
- Rollback: revert Creature removal signal, Main capture handler, regressions và docs U1.12ad.

### Gói tiếp theo

U1.12ae audit raid actor persistence theo `NEXT_UPDATE_PROMPT.md`.
