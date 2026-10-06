class_name PetMetadataCatalog
extends RefCounted

const RARITY_COMMON := &"pet.rarity.common"
const RARITY_RARE := &"pet.rarity.rare"
const RARITY_EPIC := &"pet.rarity.epic"
const RARITY_LEGENDARY := &"pet.rarity.legendary"

const TRAIT_NORMAL := &"pet.trait.normal"
const TRAIT_BRAVE := &"pet.trait.brave"
const TRAIT_AGILE := &"pet.trait.agile"
const TRAIT_WARLORD := &"pet.trait.warlord"
const TRAIT_SWIFT := &"pet.trait.swift"
const TRAIT_GUARDIAN := &"pet.trait.guardian"
const TRAIT_DRAGON_BLESSING := &"pet.trait.dragon_blessing"

const RARITY_BADGES: Dictionary = {
	RARITY_COMMON: "★ Thường",
	RARITY_RARE: "★★ Hiếm",
	RARITY_EPIC: "★★★ Sử Thi",
	RARITY_LEGENDARY: "★★★★ Thần Thoại",
}

const TRAIT_NAMES: Dictionary = {
	TRAIT_NORMAL: "Bình Thường",
	TRAIT_BRAVE: "Dũng Cảm",
	TRAIT_AGILE: "Nhanh Nhẹn",
	TRAIT_WARLORD: "Chiến Tướng",
	TRAIT_SWIFT: "Thần Tốc",
	TRAIT_GUARDIAN: "Hộ Vệ",
	TRAIT_DRAGON_BLESSING: "Thần Long Hộ Mệnh",
}


static func is_valid_rarity(rarity_id: StringName) -> bool:
	return RARITY_BADGES.has(rarity_id)


static func is_valid_trait(trait_id: StringName) -> bool:
	return TRAIT_NAMES.has(trait_id)


static func rarity_badge(rarity_id: StringName) -> String:
	return String(RARITY_BADGES.get(rarity_id, ""))


static func trait_name(trait_id: StringName) -> String:
	return String(TRAIT_NAMES.get(trait_id, ""))
