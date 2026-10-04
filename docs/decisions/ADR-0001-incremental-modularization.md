# ADR-0001 — Modular hóa theo vertical slice

Status: Accepted  
Date: 2026-10-04

## Context

Player và creature đang là god scripts hơn 1.000 dòng; data, domain logic và presentation trộn nhau. Rewrite đồng thời sẽ làm mất baseline chơi được và khó xác định regression.

## Decision

Tách module theo vertical slice nhỏ. Mỗi contract mới chạy cạnh contract cũ qua adapter; chuyển một content slice trước, kiểm chứng, rồi chuyển consumer tiếp theo. Không rewrite player, creature, HUD và world trong cùng package.

Ưu tiên: stable content IDs → typed definitions → inventory transaction → combat/capture result → pet roster → save v1. World/UI/art mở rộng dựa trên state contract này.

## Consequences

- Có code adapter tạm và đôi lúc hai representation trong thời gian migration.
- Mỗi package nhỏ hơn, rollback được và giữ game playable.
- Definition of Done phải ghi consumer nào còn dùng contract cũ.
- Adapter chỉ bị xóa khi search xác nhận không còn consumer và regression gate xanh.

