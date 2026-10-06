class_name SaveSnapshotAdapter
extends RefCounted

const Schema = preload("res://systems/save/save_v1_schema.gd")
const SnapshotResult = preload("res://systems/save/save_snapshot_result.gd")
const PetMetadata = preload("res://systems/pet/pet_metadata_catalog.gd")
const PetCommandPolicy = preload("res://systems/pet/pet_command_policy.gd")
const DEFAULT_STANCE_ID := &"pet.stance.auto_work"


static func create_player_snapshot(player: Node, save_id: StringName, saved_at_unix: int, world_clock_seconds: float = 0.0) -> RefCounted:
	if player == null or not is_instance_valid(player) or not player.has_method("get"):
		return SnapshotResult.new(SnapshotResult.Status.INVALID_SOURCE)
	var inventory_value: Variant = player.get("inventory")
	var party_value: Variant = player.get("pet_party")
	var needs: Variant = player.get("needs_state")
	if typeof(inventory_value) != TYPE_DICTIONARY or typeof(party_value) != TYPE_ARRAY or needs == null or not needs.has_method("create_snapshot"):
		return SnapshotResult.new(SnapshotResult.Status.INVALID_SOURCE)

	var errors := PackedStringArray()
	var inventory_dto := _project_inventory(inventory_value, errors)
	if not errors.is_empty():
		return SnapshotResult.new(SnapshotResult.Status.UNMAPPED_ITEM, {}, errors)
	var pets_dto := _project_pets(party_value, player.get("active_pet_node"), errors)
	if not errors.is_empty():
		return SnapshotResult.new(SnapshotResult.Status.INVALID_SOURCE, {}, errors)

	var needs_snapshot: Variant = needs.create_snapshot()
	var dto := Schema.create_empty(save_id, saved_at_unix)
	var position: Vector2 = player.global_position
	dto["player"] = {
		"position": {"x": position.x, "y": position.y},
		"level": int(player.get("level")),
		"exp": int(player.get("exp_val")),
		"hp": int(player.get("hp")),
		"max_hp": int(player.get("max_hp")),
		"stamina": float(player.get("stamina")),
		"hunger": float(needs_snapshot.hunger),
		"thirst": float(needs_snapshot.thirst),
		"temperature": float(needs_snapshot.body_temperature),
		"active_pet_instance_id": String(player.get("active_pet_instance_id")),
	}
	dto["inventory"] = inventory_dto
	dto["pets"] = pets_dto
	dto["world"]["clock_seconds"] = world_clock_seconds
	var validation: RefCounted = Schema.validate(dto)
	if not validation.is_valid():
		return SnapshotResult.new(SnapshotResult.Status.INVALID_SNAPSHOT, {}, validation.errors)
	return SnapshotResult.new(SnapshotResult.Status.ACCEPTED, dto)


static func _project_inventory(source: Dictionary, errors: PackedStringArray) -> Dictionary:
	var projected := {}
	var keys: Array = source.keys()
	keys.sort()
	for legacy_key: Variant in keys:
		var item_id := LegacyItemAdapter.to_content_id(String(legacy_key))
		if ContentId.domain_of(item_id) != &"item" or not LegacyItemAdapter.is_mapped(item_id):
			errors.append("unmapped inventory key: %s" % String(legacy_key))
			continue
		var count: Variant = source[legacy_key]
		if typeof(count) != TYPE_INT or int(count) < 0:
			errors.append("invalid inventory count: %s" % String(legacy_key))
			continue
		projected[String(item_id)] = int(count)
	return projected


static func _project_pets(source: Array, active_pet_node: Variant, errors: PackedStringArray) -> Array:
	var projected: Array = []
	for value: Variant in source:
		if typeof(value) != TYPE_DICTIONARY:
			errors.append("pet roster entry must be a Dictionary")
			continue
		var entry: Dictionary = value
		var instance_id := StringName(entry.get("instance_id", &""))
		var rarity_id := StringName(entry.get("rarity_id", &""))
		var trait_id := StringName(entry.get("trait_id", &""))
		var stance_id := StringName(entry.get("stance_id", DEFAULT_STANCE_ID))
		if is_instance_valid(active_pet_node) and StringName(active_pet_node.get("pet_instance_id")) == instance_id and active_pet_node.has_method("get_stance_id"):
			stance_id = active_pet_node.get_stance_id()
		if not PetMetadata.is_valid_rarity(rarity_id):
			errors.append("unsupported pet rarity ID: %s" % rarity_id)
			continue
		if not PetMetadata.is_valid_trait(trait_id):
			errors.append("unsupported pet trait ID: %s" % trait_id)
			continue
		if not PetCommandPolicy.VALID_STANCES.has(stance_id):
			errors.append("unsupported pet stance ID: %s" % stance_id)
			continue
		projected.append({
			"instance_id": String(instance_id),
			"species_id": String(entry.get("species_id", &"")),
			"level": int(entry.get("level", 0)),
			"exp": int(entry.get("exp", 0)),
			"rarity_id": String(rarity_id),
			"trait_id": String(trait_id),
			"stance_id": String(stance_id),
		})
	return projected
