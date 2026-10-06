class_name RuntimeInventoryManifest
extends RefCounted

const GROUPS: Dictionary = {
	"core": ["Gỗ", "Đá", "Thỏi Sắt", "Quặng Pal", "Quả Mọng Hồi Máu", "Cầu Thu Phục", "Hạt Giống Cây", "Thịt Tươi", "Thỏi Pal", "Mega Sphere", "Giga Sphere"],
	"crafting": ["Phân Bón Hữu Cơ Pal", "Bình Thuốc Tăng Thể Lực"],
	"farming": ["Phân Bón Pal", "Hạt Thảo Dược", "Hạt Lúa Mì", "Thảo Dược Pal", "Lúa Mì Hoàng Kim"],
	"ranch": ["Hạt Nhiệt Lửa", "Tinh Chất Thạch Lam", "Thảo Dược Pal", "Thịt Tươi", "Quả Mọng Hồi Máu"],
	"cooking": ["Thịt Nướng Xông Khói", "Súp Hầm Sơn Hào", "Nước Tinh Khiết Đun Sôi", "Mứt Dâu Rừng Dẻo", "Bánh Mì Lúa Mì Nướng"],
}


static func all_legacy_keys() -> PackedStringArray:
	var unique := {}
	for group_value: Variant in GROUPS.values():
		for legacy_key: Variant in group_value:
			unique[String(legacy_key)] = true
	var keys := PackedStringArray(unique.keys())
	keys.sort()
	return keys
