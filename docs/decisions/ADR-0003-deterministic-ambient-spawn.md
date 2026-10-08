# ADR-0003 — Deterministic ambient spawn resolution

Status: Accepted

Date: 2026-10-08

## Context

Ambient spawn cũ gọi RNG toàn cục trong Main, đếm mọi creature child và chọn pack/position tại thời điểm timer. Kết quả phụ thuộc call order, có thể vượt budget, trộn boss/raid và reroll khó tái hiện khi chunk streaming cập nhật.

## Decision

Spawn decision là pure policy nhận canonical active chunk keys, biome, time bucket, explicit integer seed, budget và owned ambient snapshot. Stable slot identity được suy ra từ chunk coordinate + slot. Species, position và level dùng stable FNV-1a-style integer mixer nội bộ trên key/slot/time/seed; không đọc global RNG hoặc Node state.

Actor còn active giữ nguyên resolved spec khi time bucket/seed đổi; entropy chỉ resolve slot thiếu. Runtime adapter sở hữu registry ambient riêng và scene instantiation, còn boss/night raid giữ owner hiện hữu.

## Consequences

- Cùng input tạo cùng spec và regression có thể replay chính xác.
- Thay mixer, candidate ordering hoặc slot identity là behavior/data compatibility change, phải có migration/explicit reset nếu ambient state được persist sau này.
- Population hiện transient nên defeat/capture cooldown chưa được bảo toàn qua reload/re-admission.
- Weighted biome table và authored spawn points có thể thay candidate tuning nhưng không được lấy global RNG làm authority.
