# U1.10a — PetInstance identity contract

## Phạm vi

U1.10a tạo identity bền vững cho từng pet được sở hữu mà không thay backing roster `Player.pet_party`, summon, ranch, job, UI hoặc save. Capture ownership resolver vẫn thuần và deterministic: caller phải inject `pet_instance_id`; resolver không đọc clock, RNG, Node hay SceneTree.

## Identity và typed projection

- `PetInstance.instance_id` dùng grammar `pet.<local_name>` của `ContentId`; đây là identity của cá thể.
- `PetInstance.species_id` dùng stable content ID `creature.*`; nhiều instance có thể cùng species.
- Display name, rarity badge, trait text, array index, Node instance ID và asset path không phải identity.
- `PetInstance` là typed `RefCounted` snapshot/projection. `to_party_entry()` deep-copy dữ liệu về dictionary compatibility hiện tại; không tạo roster thứ hai.

Stats rolled, EXP, needs, skills và assignment sẽ được typed dần trước Save v1; package này không tuyên bố dictionary hiện tại là DTO save hoàn chỉnh.

## Capture → roster boundary

1. Player tạo candidate ID bằng `ResourceUID.create_id()` và namespace `pet.instance_*`.
2. Player kiểm tra collision với roster hiện tại rồi inject ID vào `CaptureOwnershipRequest`.
3. Resolver reject ID rỗng/sai domain, species không hỗ trợ hoặc payload không hợp lệ.
4. Resolver tạo `PetInstance`, validate rồi project thành một party entry chứa cả `instance_id` và `species_id`.
5. Chỉ accepted result mới append roster, commit capture token và phát reward như contract U1.7c.

Capture token vẫn chỉ chống callback lặp trong runtime và không thay thế pet instance ID. Resolver test dùng ID cố định để cùng request luôn cho cùng result.

## Compatibility và validation

- `pet_party` vẫn là single source of truth; field cũ `species_data`, `level`, `rarity_badge`, `trait` được giữ nguyên.
- `swap_active_pet()` và ranch vẫn đọc dictionary theo index trong U1.10a; migrate active selection/lifecycle theo instance ID ở U1.10b.
- `tools/validate_capture.gd` khóa domain validation, deterministic projection, deep-copy, unique ID giữa hai capture và atomic duplicate guard.
- Save/data breaking change: none vì chưa có save schema. Asset/provenance: none.
- Rollback: revert U1.10a; roster runtime cũ không cần migration.
