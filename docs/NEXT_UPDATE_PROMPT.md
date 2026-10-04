# Prompt triển khai package U1.5

Làm việc tại D:\desktop\VS_WorkSpace\game2d. Đọc AGENTS.md, docs/INDEX.md, docs/CHECKPOINT.md, roadmap, docs/architecture/MODULES.md và G04 trong docs/gameplay/FEATURES.md. Audit player.gd, creature.gd, melee/slash/projectile trước khi thiết kế. Chạy baseline gate.

U1.1–U1.4 đã VERIFIED. Inventory foundation không phải scope combat; không mở rộng chest/crafting trong U1.5.

Thực hiện một package U1.5 nhỏ:

1. Ghi inventory các đường gây/nhận damage hiện có, faction filtering, reward/death side effect và duplicate-hit risk.
2. Tạo pure DamageRequest/DamageResult và CombatResolver deterministic. Input tối thiểu: source/target ID hoặc faction, base damage, defense/modifier, tags, hit position/knockback. Result: applied damage, remaining HP, defeated, knockback/status flags.
3. Không dùng Node/animation/audio trong resolver; clamp HP/damage và reject friendly/invalid request rõ ràng.
4. Migrate đúng Player + một wild Creature damage boundary. Giữ method adapter cũ cho caller chưa migrate.
5. Presentation chỉ chạy sau result và không sửa damage.
6. Regression: zero/negative, defense clamp, lethal exactly once, friendly filter, deterministic same input, HP không âm, adapter compatibility.
7. Không refactor creature FSM/skills/capture cùng package.

Kết thúc full gate, docs/checkpoint, commit branch và fast-forward main. Ghi API, migrated callers, legacy paths, save/asset impact, rollback và bước đầu U1.6.
