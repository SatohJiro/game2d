class_name CookingViewModel
extends RefCounted

## Typed card data for the cooking modal (U3.2).
##
## Built from domain state (recipes, inventory); the HUD only renders the
## resulting cards and emits cooking_requested intents. The cooking pot
## (coordinator) owns the modal session and executes the actual cooking.

var cards: Array[Dictionary] = []


static func from_recipes(recipes: Array, inventory: Dictionary) -> CookingViewModel:
	var vm := CookingViewModel.new()
	for raw in recipes:
		if not raw is Dictionary:
			continue
		var rec: Dictionary = raw
		var cost: Dictionary = rec.get("cost", {})
		var cost_parts: Array[String] = []
		var can_afford := true
		for mat in cost:
			var need := int(cost[mat])
			var have := int(inventory.get(mat, 0))
			cost_parts.append("%s: %d/%d" % [mat, have, need])
			if have < need:
				can_afford = false
		vm.cards.append({
			"id": String(rec.get("id", "")),
			"name": String(rec.get("name", "")),
			"desc": String(rec.get("desc", "")),
			"icon": rec.get("icon"),
			"cost_text": "Nguyên liệu: " + " • ".join(cost_parts),
			"can_afford": can_afford,
		})
	return vm
