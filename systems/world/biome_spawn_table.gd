class_name BiomeSpawnTable
extends RefCounted

## Authored per-biome ambient spawn table (U2.8).
##
## Pure data, no logic: maps a biome ID to a weighted species pool, a level
## range and a per-chunk slot budget. Tables are identified by stable content
## IDs (biome.<id>). Weighted picks and level rolls live in
## AmbientSpawnPolicy so this class stays a data container.
## Unknown biomes fall back to the default meadow table with a warning.

var biome_id: StringName
var species_ids: Array[StringName]
var species_weights: Array[int]
var level_min: int
var level_max: int
var slots_per_chunk: int


func _init(p_biome_id: StringName, p_species_ids: Array[StringName], p_species_weights: Array[int], p_level_min: int, p_level_max: int, p_slots_per_chunk: int) -> void:
	biome_id = p_biome_id
	species_ids = p_species_ids.duplicate()
	species_weights = p_species_weights.duplicate()
	level_min = p_level_min
	level_max = p_level_max
	slots_per_chunk = p_slots_per_chunk


func is_valid() -> bool:
	if ContentId.domain_of(biome_id) != &"biome":
		return false
	if species_ids.is_empty() or species_ids.size() != species_weights.size():
		return false
	for i in species_ids.size():
		var species_id := species_ids[i]
		if not LegacySpeciesAdapter.is_supported(species_id) or species_id == LegacySpeciesAdapter.DRAGON_ID:
			return false
		if species_weights[i] <= 0:
			return false
	if level_min < 1 or level_max > 5 or level_min > level_max:
		return false
	if slots_per_chunk < 1:
		return false
	return true


func total_weight() -> int:
	var total := 0
	for weight in species_weights:
		total += weight
	return total


static func authored_tables() -> Dictionary:
	return {
		WorldChunkCatalog.DEFAULT_BIOME_ID: BiomeSpawnTable.new(
			WorldChunkCatalog.DEFAULT_BIOME_ID,
			[LegacySpeciesAdapter.FLAM_ID, LegacySpeciesAdapter.SLIME_ID, LegacySpeciesAdapter.MUSHROOM_ID, LegacySpeciesAdapter.BEAST_ID],
			[1, 1, 1, 1],
			1,
			3,
			2
		),
	}


static func get_for_biome(biome_id: StringName) -> BiomeSpawnTable:
	var tables := authored_tables()
	if tables.has(biome_id):
		return tables[biome_id]
	push_warning("Unknown biome '%s'; falling back to default '%s'." % [String(biome_id), String(WorldChunkCatalog.DEFAULT_BIOME_ID)])
	return tables[WorldChunkCatalog.DEFAULT_BIOME_ID]
