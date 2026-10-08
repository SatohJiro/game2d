class_name CraftingViewModel
extends RefCounted

## Typed card data for the crafting modal (U3.2).
##
## Built from domain state (recipes, inventory, base level); the HUD only
## renders the resulting cards and emits recipe_crafted intents. Affordability
## is computed here, not in the card builder.

var cards: Array[Dictionary] = []


static func from_recipes(recipes: Array, inventory: Dictionary, base_level: int) -> CraftingViewModel:
	var vm := CraftingViewModel.new()
	for raw in recipes:
		if not raw is Dictionary:
			continue
		var rec: Dictionary = raw
		var cost_parts: Array[String] = []
		var can_afford := true
		var reqs: Dictionary = rec.get("req", {})
		for mat in reqs:
			var need := int(reqs[mat])
			var have := int(inventory.get(mat, 0))
			cost_parts.append("%s: %d/%d" % [mat, have, need])
			if have < need:
				can_afford = false
		var level_req := int(rec.get("base_lvl", 1))
		if base_level < level_req:
			can_afford = false
			cost_parts.append("[Cần Căn Cứ Lv.%d]" % level_req)
		vm.cards.append({
			"id": String(rec.get("id", "")),
			"name": String(rec.get("name", "Vật phẩm")),
			"desc": String(rec.get("desc", "")),
			"icon": rec.get("icon"),
			"cost_text": " • ".join(cost_parts),
			"can_afford": can_afford,
		})
	return vm
