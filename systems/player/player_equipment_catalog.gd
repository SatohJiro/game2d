class_name PlayerEquipmentCatalog
extends RefCounted

const WOOD_SWORD := &"equipment.weapon.wood_sword"
const IRON_SWORD := &"equipment.weapon.iron_sword"
const PAL_BLADE := &"equipment.weapon.pal_blade"
const NO_ARMOR := &"equipment.armor.none"
const PAL_WARRIOR_ARMOR := &"equipment.armor.pal_warrior"

const WEAPON_DAMAGE := {
	WOOD_SWORD: 22,
	IRON_SWORD: 48,
	PAL_BLADE: 85,
}
const ARMOR_MAX_HP_BONUS := {
	NO_ARMOR: 0,
	PAL_WARRIOR_ARMOR: 60,
}
const WEAPON_PRESENTATION := {
	WOOD_SWORD: "Kiếm Gỗ Sơ Cấp",
	IRON_SWORD: "Kiếm Sắt Rèn Kỹ",
	PAL_BLADE: "Đao Thần Long Pal",
}


static func is_valid_weapon(equipment_id: StringName) -> bool:
	return WEAPON_DAMAGE.has(equipment_id)


static func is_valid_armor(equipment_id: StringName) -> bool:
	return ARMOR_MAX_HP_BONUS.has(equipment_id)


static func weapon_damage(equipment_id: StringName) -> int:
	return int(WEAPON_DAMAGE.get(equipment_id, 0))


static func armor_max_hp_bonus(equipment_id: StringName) -> int:
	return int(ARMOR_MAX_HP_BONUS.get(equipment_id, 0))


static func weapon_display_name(equipment_id: StringName) -> String:
	return String(WEAPON_PRESENTATION.get(equipment_id, ""))


static func weapon_id_from_legacy(display_name: String, damage: int) -> StringName:
	for equipment_id: StringName in WEAPON_DAMAGE:
		if WEAPON_PRESENTATION[equipment_id] == display_name and WEAPON_DAMAGE[equipment_id] == damage:
			return equipment_id
	return &""


static func armor_id_from_legacy(has_armor: bool) -> StringName:
	return PAL_WARRIOR_ARMOR if has_armor else NO_ARMOR
