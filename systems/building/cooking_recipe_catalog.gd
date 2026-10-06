class_name CookingRecipeCatalog
extends RefCounted

const LEGACY_TO_ID := {
	"cooked_meat": &"recipe.cooking.smoked_meat",
	"hearty_stew": &"recipe.cooking.hearty_stew",
	"purified_water": &"recipe.cooking.purified_water",
	"berry_jam": &"recipe.cooking.berry_jam",
	"fresh_bread": &"recipe.cooking.golden_wheat_bread",
}
const DURATION_BY_ID := {
	&"recipe.cooking.smoked_meat": 2.5,
	&"recipe.cooking.hearty_stew": 3.5,
	&"recipe.cooking.purified_water": 1.8,
	&"recipe.cooking.berry_jam": 2.0,
	&"recipe.cooking.golden_wheat_bread": 2.8,
}


static func from_legacy(legacy_id: String) -> StringName:
	return LEGACY_TO_ID.get(legacy_id, &"")


static func to_legacy(recipe_id: StringName) -> String:
	for legacy_id: String in LEGACY_TO_ID:
		if LEGACY_TO_ID[legacy_id] == recipe_id:
			return legacy_id
	return ""


static func is_supported(recipe_id: StringName) -> bool:
	return DURATION_BY_ID.has(recipe_id)


static func get_duration(recipe_id: StringName) -> float:
	return float(DURATION_BY_ID.get(recipe_id, 0.0))
