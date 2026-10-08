class_name AmbientSpawnAdapter
extends RefCounted

var container: Node2D
var actor_scene: PackedScene
var applied_revision: int = 0
var cooldown_state := AmbientCooldownState.new()
var world_clock_seconds: float = 0.0
var _actors: Dictionary = {}
var _actor_chunks: Dictionary = {}
var _actor_species: Dictionary = {}


func _init(p_container: Node2D, p_actor_scene: PackedScene) -> void:
	container = p_container
	actor_scene = p_actor_scene


func reconcile(request: AmbientSpawnRequest) -> AmbientSpawnResult:
	_prune_freed()
	if not is_instance_valid(container) or actor_scene == null or request == null or request.existing_chunks != _actor_chunks:
		return AmbientSpawnResult.new(AmbientSpawnResult.Status.INVALID, [], [], get_active_ids(), applied_revision)
	var result := AmbientSpawnPolicy.resolve(request, applied_revision)
	if not result.is_success(): return result
	var staged: Dictionary = {}
	for spec in result.admitted:
		var actor := actor_scene.instantiate() as Node2D
		if actor == null:
			for staged_actor: Node2D in staged.values(): staged_actor.free()
			return AmbientSpawnResult.new(AmbientSpawnResult.Status.INVALID, [], [], get_active_ids(), applied_revision)
		actor.set("species_index", LegacySpeciesAdapter.to_legacy_index(spec.species_id))
		actor.set("level", spec.level)
		actor.position = spec.position
		actor.set_meta("ambient_spawn_id", spec.instance_id)
		actor.set_meta("ambient_chunk_key", spec.chunk_key)
		actor.set_meta("ambient_species_id", spec.species_id)
		staged[spec.instance_id] = actor
	for instance_id in result.unloaded_ids: _free_actor(instance_id)
	for instance_id in staged:
		var actor := staged[instance_id] as Node2D
		container.add_child(actor)
		actor.defeated.connect(_on_ambient_actor_defeated)
		actor.removed.connect(_on_ambient_actor_removed)
		_actors[instance_id] = actor
		_actor_chunks[instance_id] = actor.get_meta("ambient_chunk_key") as StringName
		_actor_species[instance_id] = actor.get_meta("ambient_species_id") as StringName
	applied_revision = request.chunk_revision
	return result


func create_request(center: Vector2i, active_keys: Array[StringName], biome_id: StringName, time_bucket: int, budget: int, seed: int, chunk_revision: int) -> AmbientSpawnRequest:
	_prune_freed()
	return AmbientSpawnRequest.new(center, active_keys, _actor_chunks, cooldown_state.active_ids(world_clock_seconds), biome_id, time_bucket, budget, seed, chunk_revision)


func create_cooldown_persistence_state() -> AmbientCooldownState:
	cooldown_state.prune_expired(world_clock_seconds)
	return AmbientCooldownState.from_dto(cooldown_state.to_dto())


func import_cooldown_dto(dto: Variant, clock_seconds: float) -> bool:
	var imported := AmbientCooldownState.from_dto(dto)
	if imported == null:
		return false
	cooldown_state = imported
	cooldown_state.prune_expired(clock_seconds)
	return true


func get_active_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for instance_id in _actors: ids.append(instance_id as StringName)
	ids.sort()
	return ids


func create_debug_snapshot() -> Dictionary:
	_prune_freed()
	var records: Array[Dictionary] = []
	for instance_id in get_active_ids():
		var actor := _actors[instance_id] as Node2D
		records.append({"instance_id": String(instance_id), "chunk_key": String(_actor_chunks[instance_id]), "species_id": String(_actor_species[instance_id]), "position": actor.position})
	return {"revision": applied_revision, "active_count": records.size(), "actors": records}


func cleanup() -> void:
	for instance_id in get_active_ids(): _free_actor(instance_id)


func _prune_freed() -> void:
	for instance_id in _actors.keys():
		if not is_instance_valid(_actors[instance_id]):
			_actors.erase(instance_id)
			_actor_chunks.erase(instance_id)
			_actor_species.erase(instance_id)


func _free_actor(instance_id: StringName) -> void:
	var actor: Variant = _actors.get(instance_id)
	_actors.erase(instance_id)
	_actor_chunks.erase(instance_id)
	_actor_species.erase(instance_id)
	if is_instance_valid(actor): (actor as Node).queue_free()


func _on_ambient_actor_defeated(actor: Node2D, _encounter_instance_id: StringName) -> void:
	_register_ambient_removal(actor)


func _on_ambient_actor_removed(actor: Node2D, _encounter_instance_id: StringName, _reason_id: StringName) -> void:
	_register_ambient_removal(actor)


func _register_ambient_removal(actor: Node2D) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if not actor.has_meta("ambient_spawn_id"):
		return
	var instance_id := actor.get_meta("ambient_spawn_id") as StringName
	if not AmbientCooldownState.is_valid_slot_id(instance_id):
		return
	cooldown_state.register(instance_id, world_clock_seconds + AmbientCooldownState.COOLDOWN_SECONDS)
	_actors.erase(instance_id)
	_actor_chunks.erase(instance_id)
	_actor_species.erase(instance_id)
