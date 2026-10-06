class_name PetInstance
extends RefCounted

var instance_id: StringName
var species_id: StringName
var species_data: Dictionary
var level: int
var rarity_badge: String
var trait_name: String


func _init(
	p_instance_id: StringName,
	p_species_id: StringName,
	p_species_data: Dictionary,
	p_level: int,
	p_rarity_badge: String,
	p_trait_name: String
) -> void:
	instance_id = p_instance_id
	species_id = p_species_id
	species_data = p_species_data.duplicate(true)
	level = p_level
	rarity_badge = p_rarity_badge
	trait_name = p_trait_name


func is_valid() -> bool:
	return (
		ContentId.domain_of(instance_id) == &"pet"
		and LegacySpeciesAdapter.is_supported(species_id)
		and level > 0
		and not species_data.is_empty()
		and StringName(species_data.get("id", &"")) == species_id
	)


func to_party_entry() -> Dictionary:
	if not is_valid():
		return {}
	return {
		"instance_id": instance_id,
		"species_id": species_id,
		"species_data": species_data.duplicate(true),
		"level": level,
		"rarity_badge": rarity_badge,
		"trait": trait_name,
	}
