extends Node2D

@onready var creature_container: Node2D = $Creatures
@onready var hud: CanvasLayer = $HUD
@onready var campfire_light: PointLight2D = $Environment/BaseCamp/Campfire/FlameLight
@onready var decorations: Node2D = $Environment/Decorations
@onready var water_pond: Node2D = $Environment/WaterPond
@onready var player: CharacterBody2D = $Player

const CREATURE_SCENE = preload("res://scenes/creature.tscn")
const SPARK_TEX = preload("res://assets/fx/spark.png")
const DEFAULT_SAVE_PATH := "user://saves/slot_1.json"
const WORLD_BOSS_CAPTURED_REASON := &"creature.removal.captured"
const NIGHT_RAID_ACTOR_GROUP := &"persistent_night_raid_actors"

var max_wild_creatures: int = 10
var spawn_timer: float = 3.0

var spawn_offsets: Array = [
	Vector2(260, -180),
	Vector2(380, 80),
	Vector2(220, 260),
	Vector2(-240, 220),
	Vector2(-350, -120),
	Vector2(-220, -260),
	Vector2(420, -220)
]

var day_time: float = 0.0
var day_duration: float = 180.0
var ambient_modulate: CanvasModulate = null
var boss_spawned: bool = false
var boss_timer: float = 50.0
var world_boss_state := WorldBossState.new()
var world_boss_actor: Node2D = null

var raid_triggered_this_cycle: bool = false
var night_raid_state := NightRaidState.new()
var night_raid_actors: Dictionary = {}
var fireflies: Array[Sprite2D] = []
var save_coordinator: RefCounted

func _ready() -> void:
	save_coordinator = SaveCoordinator.new(DEFAULT_SAVE_PATH)
	hud.add_to_group("hud")
	
	ambient_modulate = CanvasModulate.new()
	add_child(ambient_modulate)
	
	spawn_initial_creatures()
	hud.show_banner("PALORIA 2.0: CÀY CUỐC, NÔNG TRẠI, CHĂN NUÔI & SĂN PET!\n[E] Nông Trại/Chuồng Thú | Chuột Phải Ném Cầu (Quỹ đạo vòng cung) | [G] Kỹ Năng Pet | [C] Chế Tạo", 6.5)

func configure_save_path(primary_path: String) -> bool:
	if primary_path.is_empty(): return false
	save_coordinator = SaveCoordinator.new(primary_path)
	return true

func save_game(saved_at_unix: int, save_id: StringName = &"save.slot_1") -> RefCounted:
	if save_coordinator == null:
		save_coordinator = SaveCoordinator.new(DEFAULT_SAVE_PATH)
	var boss_state := create_world_boss_persistence_state()
	if boss_state == null:
		boss_state = WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, 0, Vector2.ZERO)
	var raid_state := create_night_raid_persistence_state()
	if raid_state == null:
		return SaveCoordinatorResult.new(SaveCoordinatorResult.Status.SNAPSHOT_FAILED)
	return save_coordinator.save_player(player, save_id, saved_at_unix, day_time, raid_triggered_this_cycle, boss_spawned, boss_timer, spawn_timer, boss_state, raid_state)

func load_game() -> RefCounted:
	if save_coordinator == null:
		save_coordinator = SaveCoordinator.new(DEFAULT_SAVE_PATH)
	var result: RefCounted = save_coordinator.load_player(player)
	if result.is_loaded():
		apply_world_cycle(result.world_clock_seconds, result.raid_triggered_this_cycle, result.boss_spawned, result.boss_timer, result.spawn_timer)
		apply_world_boss_state(result.world_boss_state)
		apply_night_raid_state(result.night_raid_state)
	return result

func apply_world_clock(clock_seconds: float) -> bool:
	if not is_finite(clock_seconds) or clock_seconds < 0.0: return false
	day_time = clock_seconds
	update_ambient_light(fmod(day_time / day_duration, 1.0))
	return true

func apply_world_cycle(clock_seconds: float, raid_triggered: bool, restored_boss_spawned: bool = false, restored_boss_timer: float = WorldCycleState.BOSS_SPAWN_SECONDS, restored_spawn_timer: float = WorldCycleState.INITIAL_AMBIENT_SPAWN_SECONDS) -> bool:
	var state := WorldCycleState.new(raid_triggered, restored_boss_spawned, restored_boss_timer, restored_spawn_timer)
	if not state.is_valid(clock_seconds): return false
	if not apply_world_clock(clock_seconds): return false
	raid_triggered_this_cycle = raid_triggered
	boss_spawned = restored_boss_spawned
	boss_timer = restored_boss_timer
	spawn_timer = restored_spawn_timer
	return true

func _process(delta: float) -> void:
	if campfire_light:
		campfire_light.energy = 1.35 + sin(Time.get_ticks_msec() * 0.012) * 0.25
	
	day_time += delta
	var progress = fmod(day_time / day_duration, 1.0)
	update_ambient_light(progress)
	
	# Atmosphere: Wind sway on flowers & bushes
	if decorations:
		var w_time = Time.get_ticks_msec() * 0.0025
		for child in decorations.get_children():
			if child is Sprite2D:
				child.rotation = sin(w_time + child.position.x * 0.05) * 0.04
	
	# Atmosphere: Water pond shimmer
	if water_pond and water_pond.has_node("WaterTile"):
		var w_tile = water_pond.get_node("WaterTile")
		w_tile.modulate = Color(0.85 + sin(Time.get_ticks_msec() * 0.003) * 0.15, 0.95, 1.1)
	
	# Night Fireflies logic
	update_fireflies(progress, delta)
	
	# Night Raid check (at 72% of day cycle)
	if progress >= 0.72 and progress < 0.92 and not raid_triggered_this_cycle:
		trigger_night_raid()
	elif progress < 0.20 and raid_triggered_this_cycle and night_raid_state.lifecycle_id != NightRaidState.ACTIVE:
		raid_triggered_this_cycle = false
		night_raid_state = NightRaidState.new()
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = 4.0
		maintain_creatures()
	
	if not boss_spawned:
		boss_timer -= delta
		if boss_timer <= 0.0:
			spawn_boss()

func update_ambient_light(progress: float) -> void:
	if not ambient_modulate:
		return
	
	var col = Color.WHITE
	if progress < 0.45:
		col = Color(1.0, 1.0, 1.0)
	elif progress < 0.65:
		var t = (progress - 0.45) / 0.2
		col = Color.WHITE.lerp(Color(1.0, 0.78, 0.55), t)
	elif progress < 0.88:
		var t = (progress - 0.65) / 0.23
		col = Color(1.0, 0.78, 0.55).lerp(Color(0.42, 0.48, 0.75), t)
	else:
		var t = (progress - 0.88) / 0.12
		col = Color(0.42, 0.48, 0.75).lerp(Color.WHITE, t)
	
	ambient_modulate.color = col

func update_fireflies(progress: float, delta: float) -> void:
	var is_night = progress >= 0.65 and progress < 0.95
	
	if is_night and fireflies.size() < 14:
		# Spawn fireflies
		var ff = Sprite2D.new()
		ff.texture = SPARK_TEX
		ff.modulate = Color(0.4, 1.0, 0.6, 0.0)
		ff.scale = Vector2(0.5, 0.5)
		ff.global_position = Vector2(randf_range(-300, 300), randf_range(-250, 250))
		add_child(ff)
		fireflies.append(ff)
	elif not is_night and fireflies.size() > 0:
		for ff in fireflies:
			if is_instance_valid(ff):
				ff.queue_free()
		fireflies.clear()
		return
	
	# Animate active fireflies floating around
	var t_msec = Time.get_ticks_msec() * 0.002
	for i in range(fireflies.size()):
		var ff = fireflies[i]
		if is_instance_valid(ff):
			ff.position += Vector2(sin(t_msec + i) * 12.0, cos(t_msec + i * 1.5) * 8.0) * delta
			ff.modulate.a = clampf(0.4 + sin(t_msec * 2.0 + i) * 0.4, 0.1, 0.85)

func trigger_night_raid(show_presentation: bool = true) -> bool:
	if raid_triggered_this_cycle or night_raid_state.lifecycle_id != NightRaidState.PENDING or not night_raid_actors.is_empty():
		return false
	var resolved_spawns: Array[Dictionary] = []
	for i in range(NightRaidActorState.VALID_INSTANCE_IDS.size()):
		var angle := randf_range(0.0, TAU)
		resolved_spawns.append({
			"instance_id": NightRaidActorState.VALID_INSTANCE_IDS[i],
			"position": Vector2(cos(angle), sin(angle)) * randf_range(320.0, 380.0),
			"species_index": randi() % NightRaidActorState.VALID_SPECIES_IDS.size(),
			"level": randi_range(2, 5),
		})
	var actor_states: Array[NightRaidActorState] = []
	for spawn: Dictionary in resolved_spawns:
		var creature = CREATURE_SCENE.instantiate()
		var instance_id := spawn["instance_id"] as StringName
		creature.global_position = spawn["position"] as Vector2
		creature.species_index = spawn["species_index"] as int
		creature.level = spawn["level"] as int
		creature.is_night_raider = true
		creature.set_meta("encounter_id", NightRaidState.ENCOUNTER_ID)
		creature.set_meta("encounter_instance_id", instance_id)
		creature.add_to_group(NIGHT_RAID_ACTOR_GROUP)
		creature_container.add_child(creature)
		creature.scale = Vector2(1.2, 1.2)
		creature.attack_power = int(creature.attack_power * 1.25)
		creature.target = player
		creature.defeated.connect(_on_night_raid_actor_defeated)
		creature.removed.connect(_on_night_raid_actor_removed)
		night_raid_actors[instance_id] = creature
		var species_id := creature.cur_data.get("id", &"") as StringName
		actor_states.append(NightRaidActorState.new(instance_id, species_id, creature.level, creature.hp, creature.global_position))
	raid_triggered_this_cycle = true
	night_raid_state = NightRaidState.new(NightRaidState.ACTIVE, NightRaidState.ENCOUNTER_ID, int(floor(day_time / day_duration)), actor_states)
	if show_presentation:
		hud.show_banner("⚠️ BÁO ĐỘNG: ĐÊM XÂM LĂNG! BẦY QUÁI MẮT ĐỎ ĐANG TIẾN VỀ CĂN CỨ!", 6.0)
		if AudioManager:
			AudioManager.play_sound("shake")
	return true

func _on_night_raid_actor_defeated(actor: Node2D, encounter_instance_id: StringName) -> void:
	commit_night_raid_actor_removal(actor, encounter_instance_id)

func _on_night_raid_actor_removed(actor: Node2D, encounter_instance_id: StringName, reason_id: StringName) -> void:
	if reason_id == WORLD_BOSS_CAPTURED_REASON:
		commit_night_raid_actor_removal(actor, encounter_instance_id)

func commit_night_raid_actor_removal(actor: Node2D, encounter_instance_id: StringName) -> bool:
	if night_raid_state.lifecycle_id != NightRaidState.ACTIVE or actor == null:
		return false
	if not NightRaidActorState.VALID_INSTANCE_IDS.has(encounter_instance_id):
		return false
	if night_raid_actors.get(encounter_instance_id) != actor:
		return false
	if not actor.is_in_group(NIGHT_RAID_ACTOR_GROUP):
		return false
	if actor.get_meta("encounter_id", &"") as StringName != NightRaidState.ENCOUNTER_ID:
		return false
	if actor.get_meta("encounter_instance_id", &"") as StringName != encounter_instance_id:
		return false
	night_raid_actors.erase(encounter_instance_id)
	var remaining: Array[NightRaidActorState] = []
	for actor_state in night_raid_state.actors:
		if actor_state.instance_id != encounter_instance_id:
			remaining.append(actor_state)
	var lifecycle_id := NightRaidState.ACTIVE if not remaining.is_empty() else NightRaidState.CLEARED
	night_raid_state = NightRaidState.new(lifecycle_id, NightRaidState.ENCOUNTER_ID, night_raid_state.cycle_index, remaining)
	return true


func get_world_chunk_context(world_position: Vector2) -> WorldChunkContext:
	return WorldChunkCatalog.resolve_world_position(world_position)

func create_night_raid_persistence_state() -> NightRaidState:
	if night_raid_state.lifecycle_id != NightRaidState.ACTIVE:
		return NightRaidState.from_dto(night_raid_state.to_dto())
	var actors: Array[NightRaidActorState] = []
	for actor_state in night_raid_state.actors:
		var actor: Node2D = night_raid_actors.get(actor_state.instance_id)
		if not is_instance_valid(actor): return null
		var projected := NightRaidActorState.new(actor_state.instance_id, actor_state.species_id, int(actor.get("level")), int(actor.get("hp")), actor.global_position)
		if not projected.is_valid(): return null
		actors.append(projected)
	return NightRaidState.new(NightRaidState.ACTIVE, NightRaidState.ENCOUNTER_ID, night_raid_state.cycle_index, actors)

func apply_night_raid_state(state: NightRaidState) -> bool:
	if state == null or not state.is_coherent(raid_triggered_this_cycle, day_time): return false
	_remove_night_raid_actors()
	if state.lifecycle_id == NightRaidState.ACTIVE:
		var restored: Dictionary = {}
		for actor_state in state.actors:
			var creature = CREATURE_SCENE.instantiate()
			creature.global_position = actor_state.position
			creature.species_index = LegacySpeciesAdapter.to_legacy_index(actor_state.species_id)
			creature.level = actor_state.level
			creature.is_night_raider = true
			creature.set_meta("encounter_id", NightRaidState.ENCOUNTER_ID)
			creature.set_meta("encounter_instance_id", actor_state.instance_id)
			creature.add_to_group(NIGHT_RAID_ACTOR_GROUP)
			creature_container.add_child(creature)
			creature.scale = Vector2(1.2, 1.2)
			creature.attack_power = int(creature.attack_power * 1.25)
			creature.target = player
			creature.hp = actor_state.hp
			creature.update_overhead()
			creature.defeated.connect(_on_night_raid_actor_defeated)
			creature.removed.connect(_on_night_raid_actor_removed)
			restored[actor_state.instance_id] = creature
		night_raid_actors = restored
	night_raid_state = NightRaidState.from_dto(state.to_dto())
	return true

func _remove_night_raid_actors() -> void:
	for actor: Node in get_tree().get_nodes_in_group(NIGHT_RAID_ACTOR_GROUP):
		if is_instance_valid(actor):
			if actor.get_parent() != null: actor.get_parent().remove_child(actor)
			actor.free()
	night_raid_actors.clear()

func spawn_boss(show_presentation: bool = true) -> bool:
	if world_boss_state.lifecycle_id != WorldBossState.PENDING or is_instance_valid(world_boss_actor):
		return false
	boss_spawned = true
	boss_timer = 0.0
	var creature = CREATURE_SCENE.instantiate()
	creature.global_position = Vector2(340, 220)
	creature.species_index = 4 # Dragon Boss
	creature.level = 8
	creature.set_meta("encounter_instance_id", WorldBossState.INSTANCE_ID)
	creature.add_to_group("persistent_world_bosses")
	creature_container.add_child(creature)
	world_boss_actor = creature
	
	var vis = creature.get_node_or_null("Visual")
	if vis: vis.scale = Vector2(2.2, 2.2)
	var col = creature.get_node_or_null("CollisionShape2D")
	if col: col.scale = Vector2(1.8, 1.8)
	var ovh = creature.get_node_or_null("Overhead")
	if ovh: ovh.position.y = -50.0
	
	creature.max_hp = 380
	creature.hp = 380
	creature.attack_power = 28
	creature.update_overhead()
	world_boss_state = WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, creature.hp, creature.global_position)
	creature.defeated.connect(_on_world_boss_defeated)
	creature.removed.connect(_on_world_boss_removed)
	
	if show_presentation:
		hud.show_banner("⚠️ CẢNH BÁO: HỎA LONG THẦN (DRAGON BOSS LV.8) ĐÃ XUẤT HIỆN!", 6.5)
		if AudioManager:
			AudioManager.play_sound("level_up")
	return true

func _on_world_boss_defeated(actor: Node2D, encounter_instance_id: StringName) -> void:
	commit_world_boss_defeat(actor, encounter_instance_id)

func _on_world_boss_removed(actor: Node2D, encounter_instance_id: StringName, reason_id: StringName) -> void:
	commit_world_boss_removal(actor, encounter_instance_id, reason_id)

func commit_world_boss_defeat(actor: Node2D, encounter_instance_id: StringName) -> bool:
	return _commit_world_boss_terminal(actor, encounter_instance_id)

func commit_world_boss_removal(actor: Node2D, encounter_instance_id: StringName, reason_id: StringName) -> bool:
	if reason_id != WORLD_BOSS_CAPTURED_REASON: return false
	return _commit_world_boss_terminal(actor, encounter_instance_id)

func _commit_world_boss_terminal(actor: Node2D, encounter_instance_id: StringName) -> bool:
	if not is_instance_valid(actor) or actor != world_boss_actor: return false
	if encounter_instance_id != WorldBossState.INSTANCE_ID: return false
	if not actor.is_in_group("persistent_world_bosses"): return false
	if actor.get_meta("encounter_instance_id", &"") as StringName != WorldBossState.INSTANCE_ID: return false
	world_boss_state = WorldBossState.new(WorldBossState.DEFEATED, WorldBossState.INSTANCE_ID, 0, Vector2.ZERO)
	world_boss_actor = null
	return true

func create_world_boss_persistence_state() -> WorldBossState:
	if world_boss_state.lifecycle_id == WorldBossState.ACTIVE:
		if not is_instance_valid(world_boss_actor): return null
		var projected := WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, int(world_boss_actor.get("hp")), world_boss_actor.global_position)
		return projected if projected.is_valid() else null
	return WorldBossState.new(world_boss_state.lifecycle_id, world_boss_state.instance_id, world_boss_state.hp, world_boss_state.position)

func apply_world_boss_state(state: WorldBossState) -> bool:
	if state == null or not state.is_valid(): return false
	_remove_world_boss_actor()
	world_boss_state = WorldBossState.new()
	if state.lifecycle_id == WorldBossState.ACTIVE:
		boss_spawned = false
		if not spawn_boss(false): return false
		world_boss_actor.global_position = state.position
		world_boss_actor.set("hp", state.hp)
		world_boss_actor.call("update_overhead")
		world_boss_state = WorldBossState.new(WorldBossState.ACTIVE, WorldBossState.INSTANCE_ID, state.hp, state.position)
		return true
	world_boss_state = WorldBossState.new(state.lifecycle_id, state.instance_id, state.hp, state.position)
	boss_spawned = state.lifecycle_id != WorldBossState.PENDING
	if boss_spawned: boss_timer = 0.0
	return true

func _remove_world_boss_actor() -> void:
	for actor: Node in get_tree().get_nodes_in_group("persistent_world_bosses"):
		if is_instance_valid(actor):
			if actor.get_parent() != null: actor.get_parent().remove_child(actor)
			actor.free()
	world_boss_actor = null

func spawn_initial_creatures() -> void:
	# 1. Bầy Nhớt Thủy Sinh tụ tập gần hồ nước
	spawn_creature_pack(1, Vector2(240, 220), 3) # Slime Herd near Pond
	# 2. Bầy Sói Săn Beast Pack ở đồng cỏ phía Tây
	spawn_creature_pack(3, Vector2(-280, 180), 2) # Beast Hunting Pack
	# 3. Bầy Cáo Lửa Flam Pack ở khu vực phía Đông Bắc
	spawn_creature_pack(0, Vector2(320, -180), 2) # Flam Pack
	# 4. Khóm Nấm Bào Tử Mushroom Grove
	spawn_creature_pack(2, Vector2(-260, -160), 2) # Mushroom Grove

func maintain_creatures() -> void:
	var count = creature_container.get_child_count()
	if count < max_wild_creatures:
		var species = randi() % 4
		var base_pos = spawn_offsets[randi() % spawn_offsets.size()]
		var pack_size = randi_range(1, 2)
		spawn_creature_pack(species, base_pos, pack_size)

func spawn_creature_pack(species: int, center_pos: Vector2, count: int) -> void:
	var leader_assigned = false
	for i in range(count):
		var creature = CREATURE_SCENE.instantiate()
		var offset = Vector2(randf_range(-45, 45), randf_range(-45, 45))
		creature.global_position = center_pos + offset
		creature.species_index = species
		
		if not leader_assigned and count > 1:
			creature.level = randi_range(3, 5)
			creature.is_alpha = true
			leader_assigned = true
		else:
			creature.level = randi_range(1, 3)
		
		creature_container.add_child(creature)
