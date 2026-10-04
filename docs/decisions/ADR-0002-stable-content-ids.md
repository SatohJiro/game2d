# ADR-0002 — Stable content IDs và typed Resources

Status: Accepted

Date: 2026-10-04

## Context

Inventory, recipe và building hiện dùng text tiếng Việt như `Gỗ` làm dictionary key; creature/item data nằm trong script. Đổi text, localization hoặc scene path có thể phá logic và save tương lai.

## Decision

Mọi content có identity dùng lowercase dotted ID, được validate bởi `ContentId`. Data authoring dùng subtype của `ContentDefinition` và registry reject invalid/duplicate definition trước runtime. Text hiển thị dùng localization key riêng.

Migration diễn ra theo vertical slice qua adapter legacy → stable ID. Save mới chỉ lưu stable ID; Node, localized text, Resource instance và scene path không là identity persistent.

## Consequences

- Có giai đoạn hai key cùng tồn tại và cần mapping được kiểm thử.
- Content lỗi dừng gate sớm thay vì tạo fallback khó thấy.
- Đổi ID trở thành schema migration, không còn là rename thông thường.
- Definition dễ author trong Godot Inspector nhưng domain system phải coi chúng là immutable.
