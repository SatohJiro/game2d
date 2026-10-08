class_name HUDViewModel
extends RefCounted

## Read-only HUD snapshot (U3.1).
##
## Built once from the player via from_player(); the HUD only renders this
## ViewModel and emits intents — it never reads player nodes itself. The
## quest panel keeps its existing push path until the quest UI is rebuilt
## (U3.2); every other HUD block renders from this snapshot.

var hp: int = 100
var max_hp: int = 100
var stamina: float = 100.0
var max_stamina: float = 100.0
var hunger: float = 100.0
var max_hunger: float = 100.0
var thirst: float = 100.0
var max_thirst: float = 100.0
var body_temperature: float = 36.5
var level: int = 1
var exp_val: int = 0
var max_exp: int = 100
var buff_text: String = "Khỏe mạnh"
var stat_points: int = 0
var stats: Dictionary = {}
var weapon_text: String = ""
var inventory: Dictionary = {}
var pet_visible: bool = false
var pet_name: String = ""
var pet_level: int = 1
var pet_hp: int = 0
var pet_max_hp: int = 1
var pet_stance_text: String = ""


static func empty() -> HUDViewModel:
	return HUDViewModel.new()


static func from_player(player: Node) -> HUDViewModel:
	var vm := HUDViewModel.new()
	if player == null or not is_instance_valid(player):
		return vm
	vm.hp = int(player.get("hp"))
	vm.max_hp = int(player.get("max_hp"))
	vm.stamina = float(player.get("stamina"))
	vm.max_stamina = float(player.get("max_stamina"))
	vm.level = int(player.get("level"))
	vm.exp_val = int(player.get("exp_val"))
	vm.max_exp = int(player.get("max_exp"))
	vm.stat_points = int(player.get("stat_points"))
	var raw_stats: Variant = player.get("stats")
	vm.stats = (raw_stats as Dictionary).duplicate() if raw_stats is Dictionary else {}
	var weapon_name := String(player.get("weapon_name"))
	var weapon_damage := int(player.get("weapon_damage"))
	vm.weapon_text = "%s (Sát thương %d)" % [weapon_name, weapon_damage + int(vm.stats.get("str", 0)) * 3]
	var raw_inventory: Variant = player.get("inventory")
	vm.inventory = (raw_inventory as Dictionary).duplicate() if raw_inventory is Dictionary else {}
	var needs: Variant = player.get("needs_state")
	if needs != null and needs.has_method("create_snapshot"):
		var snapshot: Variant = needs.create_snapshot()
		if snapshot != null:
			vm.hunger = float(snapshot.hunger)
			vm.max_hunger = float(snapshot.max_hunger)
			vm.thirst = float(snapshot.thirst)
			vm.max_thirst = float(snapshot.max_thirst)
			vm.body_temperature = float(snapshot.body_temperature)
			var buff_display := String(snapshot.buff_display_name)
			vm.buff_text = buff_display if not buff_display.is_empty() else "Khỏe mạnh"
	var pet_node: Variant = player.get("active_pet_node")
	if pet_node != null and is_instance_valid(pet_node):
		var species_data: Variant = pet_node.get("species_data")
		var pet_name_value := "Pet"
		if species_data is Dictionary:
			pet_name_value = String((species_data as Dictionary).get("name", "Pet"))
		vm.pet_visible = true
		vm.pet_name = pet_name_value
		vm.pet_level = int(pet_node.get("level"))
		vm.pet_hp = int(pet_node.get("hp"))
		vm.pet_max_hp = maxi(1, int(pet_node.get("max_hp")))
		vm.pet_stance_text = _stance_display_text(int(pet_node.get("stance")))
	return vm


static func _stance_display_text(stance: int) -> String:
	match stance:
		0:
			return "Tự động làm việc"
		1:
			return "Tự do Tấn công"
		2:
			return "Theo sát & Phòng thủ"
	return ""
