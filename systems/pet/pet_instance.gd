class_name PetInstance
extends RefCounted

var instance_id: StringName
var species_id: StringName
var species_data: Dictionary
var level: int
var rarity_id: StringName
var trait_id: StringName
var rarity_badge: String
var trait_name: String


func _init(
	p_instance_id: StringName,
	p_species_id: StringName,
	p_species_data: Dictionary,
	p_level: int,
	p_rarity_id: StringName,
	p_trait_id: StringName,
	p_rarity_badge: String,
	p_trait_name: String
) -> void:
	instance_id = p_instance_id
	species_id = p_species_id
	species_data = p_species_data.duplicate(true)
	level = p_level
	rarity_id = p_rarity_id
	trait_id = p_trait_id
	rarity_badge = p_rarity_badge
	trait_name = p_trait_name


func is_valid() -> bool:
	return (
		ContentId.domain_of(instance_id) == &"pet"
		and LegacySpeciesAdapter.is_supported(species_id)
		and level > 0
		and PetMetadataCatalog.is_valid_rarity(rarity_id)
		and PetMetadataCatalog.is_valid_trait(trait_id)
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
		"exp": 0,
		"rarity_id": rarity_id,
		"trait_id": trait_id,
		"stance_id": &"pet.stance.auto_work",
		"rarity_badge": rarity_badge,
		"trait": trait_name,
	}
