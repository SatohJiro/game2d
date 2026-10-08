extends Node2D

@onready var creature_container: Node2D = $Creatures
@onready var hud: CanvasLayer = $HUD
@onready var campfire_light: PointLight2D = $Environment/BaseCamp/Campfire/FlameLight
@onready var water_pond: Node2D = $Environment/WaterPond
@onready var player: CharacterBody2D = $Player

const CREATURE_SCENE = preload("res://scenes/creature.tscn")
const MINIMAP_SCENE = preload("res://scenes/minimap.tscn")
const SAVE_SLOTS_SCENE = preload("res://scenes/save_slots.tscn")
const SETTINGS_SCENE = preload("res://scenes/settings.tscn")
const SPARK_TEX = preload("res://assets/fx/spark.png")
const DEFAULT_SAVE_PATH := "user://saves/slot_1.json"
const WORLD_BOSS_CAPTURED_REASON := &"creature.removal.captured"
const NIGHT_RAID_ACTOR_GROUP := &"persistent_night_raid_actors"

var max_wild_creatures: int = 10
var spawn_timer: float = 3.0

var day_time: float = 0.0
var day_duration: float = 180.0
var boss_spawned: bool = false
var boss_timer: float = 50.0
var world_boss_state := WorldBossState.new()
var world_boss_actor: Node2D = null

var raid_triggered_this_cycle: bool = false
var night_raid_state := NightRaidState.new()
var night_raid_actors: Dictionary = {}
var fireflies: Array[Sprite2D] = []
var save_coordinator: RefCounted
var chunk_admission := ChunkAdmissionCoordinator.new()
var chunk_scene_adapter: ChunkSceneAdapter
var town_builder: TownBuilder
var lighting_director: LightingDirector
var weather_director: WeatherDirector
var current_save_id: StringName = &"slot_1"
var chunk_navigation_adapter: ChunkNavigationAdapter
var ambient_spawn_adapter: AmbientSpawnAdapter
var chunk_discovery_adapter := ChunkDiscoveryAdapter.new()
var chunk_debug_overlay: ChunkDebugOverlay
var fast_travel_cooldown_until_msec: int = 0
var minimap_panel: MinimapPanel
var save_slot_manager := SaveSlotManager.new()
var save_slot_panel: SaveSlotPanel
var current_save_slot: StringName = &"slot_1"
var autosave_enabled := false
var autosave_interval := 300.0
var _autosave_elapsed := 0.0
var settings_panel: SettingsPanel
var context_prompt: ContextPrompt
var _prompt_timer := 0.0

func _ready() -> void:
	save_coordinator = SaveCoordinator.new(DEFAULT_SAVE_PATH)
	GameSettings.load()
	GameSettings.apply()
	hud.add_to_group("hud")
	
	var chunk_container := Node2D.new()
	chunk_container.name = "ChunkPlaceholders"
	add_child(chunk_container)
	chunk_scene_adapter = ChunkSceneAdapter.new(chunk_container)
	town_builder = TownBuilder.new()
	town_builder.name = "TownBuilder"
	add_child(town_builder)
	lighting_director = LightingDirector.new()
	lighting_director.name = "LightingDirector"
	add_child(lighting_director)
	weather_director = WeatherDirector.new()
	weather_director.name = "WeatherDirector"
	add_child(weather_director)
	chunk_navigation_adapter = ChunkNavigationAdapter.new(get_world_2d().navigation_map)
	ambient_spawn_adapter = AmbientSpawnAdapter.new(creature_container, CREATURE_SCENE)
	chunk_debug_overlay = ChunkDebugOverlay.new()
	chunk_debug_overlay.name = "ChunkDebugOverlay"
	add_child(chunk_debug_overlay)
	var initial_chunk_delta := chunk_admission.update_world_position(player.global_position)
	chunk_scene_adapter.apply_delta(initial_chunk_delta)
	_build_town_for_delta(initial_chunk_delta)
	chunk_navigation_adapter.apply(ChunkNavigationRequest.from_delta(initial_chunk_delta))
	chunk_discovery_adapter.observe_center(initial_chunk_delta.center)
	chunk_debug_overlay.render_snapshot(chunk_admission.create_debug_snapshot())
	minimap_panel = MINIMAP_SCENE.instantiate() as MinimapPanel
	hud.add_child(minimap_panel)
	minimap_panel.travel_requested.connect(_on_minimap_travel_requested)
	minimap_panel.render_snapshot(get_chunk_discovery_view_snapshot())
	save_slot_panel = SAVE_SLOTS_SCENE.instantiate() as SaveSlotPanel
	hud.add_child(save_slot_panel)
	save_slot_panel.load_requested.connect(_on_save_slot_load_requested)
	save_slot_panel.save_requested.connect(_on_save_slot_save_requested)
	save_slot_panel.delete_requested.connect(_on_save_slot_delete_requested)
	save_slot_panel.autosave_toggled.connect(_on_save_slot_autosave_toggled)
	save_slot_panel.render_slots(list_save_slots(), autosave_enabled, current_save_slot)
	settings_panel = SETTINGS_SCENE.instantiate() as SettingsPanel
	hud.add_child(settings_panel)
	settings_panel.volume_changed.connect(_on_settings_volume_changed)
	settings_panel.ui_scale_changed.connect(_on_settings_ui_scale_changed)
	settings_panel.reduce_motion_toggled.connect(_on_settings_reduce_motion_toggled)
	settings_panel.locale_selected.connect(_on_settings_locale_selected)
	settings_panel.remap_changed.connect(_on_settings_remap_changed)
	settings_panel.render(settings_snapshot())
	context_prompt = ContextPrompt.new()
	hud.add_child(context_prompt)
	_apply_ui_scale()
	
	maintain_creatures()
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
	return save_coordinator.save_player(player, save_id, saved_at_unix, day_time, raid_triggered_this_cycle, boss_spawned, boss_timer, spawn_timer, boss_state, raid_state, chunk_discovery_adapter.create_persistence_state(), ambient_spawn_adapter.create_cooldown_persistence_state())

func load_game() -> RefCounted:
	if save_coordinator == null:
		save_coordinator = SaveCoordinator.new(DEFAULT_SAVE_PATH)
	var result: RefCounted = save_coordinator.load_player(player)
	if result.is_loaded():
		apply_world_cycle(result.world_clock_seconds, result.raid_triggered_this_cycle, result.boss_spawned, result.boss_timer, result.spawn_timer)
		apply_world_boss_state(result.world_boss_state)
		apply_night_raid_state(result.night_raid_state)
		chunk_discovery_adapter.import_dto(result.chunk_discovery_state.to_dto())
		ambient_spawn_adapter.import_cooldown_dto(result.ambient_cooldown_state.to_dto(), result.world_clock_seconds)
	return result

func list_save_slots() -> Array[Dictionary]:
	return save_slot_manager.list_slots()

func save_game_to_slot(slot_id: StringName, saved_at_unix: int, make_current: bool = true) -> RefCounted:
	if not SaveSlotManager.is_valid_slot_id(slot_id):
		return SaveCoordinatorResult.new(SaveCoordinatorResult.Status.SNAPSHOT_FAILED)
	save_coordinator = save_slot_manager.coordinator_for(slot_id)
	if make_current:
		current_save_slot = slot_id
		current_save_id = SaveSlotManager.save_id_for_slot(slot_id)
	return save_game(saved_at_unix, SaveSlotManager.save_id_for_slot(slot_id))

func load_game_from_slot(slot_id: StringName) -> RefCounted:
	if not SaveSlotManager.is_valid_slot_id(slot_id):
		return SaveCoordinatorResult.new(SaveCoordinatorResult.Status.REPOSITORY_FAILED)
	save_coordinator = save_slot_manager.coordinator_for(slot_id)
	current_save_slot = slot_id
	current_save_id = SaveSlotManager.save_id_for_slot(slot_id)
	return load_game()

func delete_save_slot(slot_id: StringName) -> bool:
	var removed := save_slot_manager.delete_slot(slot_id)
	_refresh_save_slot_panel()
	return removed

func toggle_save_slots() -> bool:
	if save_slot_panel == null or not is_instance_valid(save_slot_panel):
		return false
	if not save_slot_panel.is_open():
		_refresh_save_slot_panel()
	return save_slot_panel.toggle()

func set_autosave_enabled(enabled: bool) -> void:
	autosave_enabled = enabled
	_autosave_elapsed = 0.0
	_refresh_save_slot_panel()

func is_autosave_safe() -> bool:
	if is_fast_travel_encounter_blocked():
		return false
	if hud.is_crafting_visible() or hud.is_cooking_modal_visible() or hud.is_stat_modal_visible():
		return false
	if minimap_panel != null and is_instance_valid(minimap_panel) and minimap_panel.is_open():
		return false
	if save_slot_panel != null and is_instance_valid(save_slot_panel) and save_slot_panel.is_open():
		return false
	return true

func try_autosave_tick(delta: float) -> bool:
	if not autosave_enabled:
		return false
	_autosave_elapsed += delta
	if _autosave_elapsed < autosave_interval:
		return false
	if not is_autosave_safe():
		return false
	_autosave_elapsed = 0.0
	var result := save_game_to_slot(SaveSlotManager.AUTOSAVE_SLOT, int(Time.get_unix_time_from_system()), false)
	if result.is_success():
		hud.show_banner(Localization.text("slots.autosaved"), 2.0)
	return result.is_success()

func _refresh_save_slot_panel() -> void:
	if save_slot_panel != null and is_instance_valid(save_slot_panel):
		save_slot_panel.render_slots(list_save_slots(), autosave_enabled, current_save_slot)

func _on_save_slot_load_requested(slot_id: StringName) -> void:
	var result := load_game_from_slot(slot_id)
	_refresh_save_slot_panel()
	hud.show_banner(Localization.text("slots.loaded", {"slot": String(slot_id)}) if result.is_loaded() else Localization.text("slots.load_failed"), 2.5)

func _on_save_slot_save_requested(slot_id: StringName) -> void:
	var result := save_game_to_slot(slot_id, int(Time.get_unix_time_from_system()))
	_refresh_save_slot_panel()
	hud.show_banner(Localization.text("slots.saved", {"slot": String(slot_id)}) if result.is_success() else Localization.text("slots.save_failed"), 2.5)

func _on_save_slot_delete_requested(slot_id: StringName) -> void:
	if delete_save_slot(slot_id):
		hud.show_banner(Localization.text("slots.deleted", {"slot": String(slot_id)}), 2.0)

func _on_save_slot_autosave_toggled(enabled: bool) -> void:
	set_autosave_enabled(enabled)
	hud.show_banner(Localization.text("slots.autosave_on") if enabled else Localization.text("slots.autosave_off"), 2.0)

func settings_snapshot() -> Dictionary:
	return {
		"master_volume": GameSettings.master_volume,
		"ui_scale": GameSettings.ui_scale,
		"reduce_motion": GameSettings.reduce_motion,
		"locale": GameSettings.locale,
		"input_remap": GameSettings.input_remap.duplicate(),
		"remap_actions": [
			{"id": PlayerActionIntent.ACTION_INTERACT, "label_key": "settings.remap_interact"},
			{"id": PlayerActionIntent.ACTION_ROLL, "label_key": "settings.remap_roll"},
			{"id": PlayerActionIntent.ACTION_CAPTURE_THROW, "label_key": "settings.remap_throw"},
		],
	}

func toggle_settings() -> bool:
	if settings_panel == null or not is_instance_valid(settings_panel):
		return false
	if not settings_panel.is_open():
		settings_panel.render(settings_snapshot())
	return settings_panel.toggle()

func _apply_ui_scale() -> void:
	var scale_factor: float = GameSettings.ui_scale
	var center := get_viewport().get_visible_rect().size * 0.5
	hud.transform = Transform2D(0, Vector2(scale_factor, scale_factor), 0, center * (1.0 - scale_factor))

func _on_settings_volume_changed(value: float) -> void:
	GameSettings.master_volume = clampf(value, 0.0, 1.0)
	GameSettings.apply()
	GameSettings.save()

func _on_settings_ui_scale_changed(value: float) -> void:
	GameSettings.ui_scale = clampf(value, 0.75, 1.5)
	_apply_ui_scale()
	GameSettings.save()

func _on_settings_reduce_motion_toggled(enabled: bool) -> void:
	GameSettings.reduce_motion = enabled
	GameSettings.save()

func _on_settings_locale_selected(locale: String) -> void:
	GameSettings.locale = locale
	GameSettings.apply()
	GameSettings.save()
	settings_panel.render(settings_snapshot())
	_refresh_save_slot_panel()

func _on_settings_remap_changed(action_id: StringName, keycode: int) -> void:
	GameSettings.input_remap[String(action_id)] = keycode
	GameSettings.apply()
	GameSettings.save()

func _prompt_key_for(target: Node) -> String:
	if target.has_method("interaction_prompt_name"):
		return String(target.call("interaction_prompt_name"))
	if String(target.name) == "WaterPond":
		return "prompt.target.water_pond"
	return "prompt.target.generic"

func _world_to_screen(world_position: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return get_viewport().get_visible_rect().size * 0.5
	return (world_position - camera.get_screen_center_position()) * camera.zoom + get_viewport().get_visible_rect().size * 0.5

func _update_context_prompt() -> void:
	if context_prompt == null or not is_instance_valid(context_prompt):
		return
	if hud.is_crafting_visible() or hud.is_cooking_modal_visible() or hud.is_stat_modal_visible():
		context_prompt.hide_prompt()
		return
	var target: Node = player.get_interaction_target()
	if target == null or not is_instance_valid(target) or not target is Node2D:
		context_prompt.hide_prompt()
		return
	var key_name := OS.get_keycode_string(PlayerActionInputMapper.action_key(PlayerActionIntent.ACTION_INTERACT))
	var text := Localization.text("prompt.interact_hint", {"key": key_name, "target": Localization.text(_prompt_key_for(target))})
	var screen_position := _world_to_screen((target as Node2D).global_position + Vector2(0, -48))
	context_prompt.show_prompt(text, screen_position)

func apply_world_clock(clock_seconds: float) -> bool:
	if not is_finite(clock_seconds) or clock_seconds < 0.0: return false
	day_time = clock_seconds
	lighting_director.update_clock(fmod(day_time / day_duration, 1.0), GameSettings.reduce_motion, 1.0)
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
	update_chunk_admission(player.global_position)
	if campfire_light:
		campfire_light.energy = 1.35 + sin(Time.get_ticks_msec() * 0.012) * 0.25
	
	day_time += delta
	var progress = fmod(day_time / day_duration, 1.0)
	lighting_director.update_clock(progress, GameSettings.reduce_motion, delta)
	var weather := weather_director.update_clock(day_time, String(current_save_id), GameSettings.reduce_motion, delta)
	_tick_audio_director(progress, weather, delta)
	
	# Atmosphere: Wind sway on chunk static decorations (U2.9: decorations live
	# under admitted chunk nodes and unload with them).
	var w_time = Time.get_ticks_msec() * 0.0025
	for sway_node in get_tree().get_nodes_in_group("chunk_static_decor"):
		if sway_node is Sprite2D:
			sway_node.rotation = sin(w_time + sway_node.position.x * 0.05) * 0.04
	
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

	if autosave_enabled:
		try_autosave_tick(delta)

	_prompt_timer += delta
	if _prompt_timer >= 0.15:
		_prompt_timer = 0.0
		_update_context_prompt()
	
	if not boss_spawned:
		boss_timer -= delta
		if boss_timer <= 0.0:
			spawn_boss()

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


func get_chunk_admission_debug_snapshot() -> Dictionary:
	return chunk_admission.create_debug_snapshot().duplicate(true)

func get_chunk_navigation_debug_snapshot() -> Dictionary:
	return chunk_navigation_adapter.create_debug_snapshot().duplicate(true) if chunk_navigation_adapter != null else {}

func get_ambient_spawn_debug_snapshot() -> Dictionary:
	return ambient_spawn_adapter.create_debug_snapshot().duplicate(true) if ambient_spawn_adapter != null else {}

func get_chunk_discovery_view_snapshot() -> Dictionary:
	return chunk_discovery_adapter.create_view_snapshot(chunk_admission.center, chunk_admission.get_active_keys())

func update_chunk_obstacle(chunk_key: StringName, obstacle_revision: int, blocked: bool) -> ChunkNavigationResult:
	if chunk_navigation_adapter == null:
		return ChunkNavigationResult.new(ChunkNavigationResult.Status.INVALID, 0, 0)
	return chunk_navigation_adapter.apply(ChunkNavigationRequest.obstacle(chunk_key, chunk_navigation_adapter.applied_revision, obstacle_revision, blocked))

func update_chunk_admission(world_position: Vector2) -> bool:
	var chunk_delta := chunk_admission.update_world_position(world_position)
	if chunk_delta.status == ChunkAdmissionDelta.Status.NO_CHANGE:
		return true
	if not chunk_delta.is_changed() or not chunk_scene_adapter.apply_delta(chunk_delta):
		return false
	_build_town_for_delta(chunk_delta)
	var navigation_result := chunk_navigation_adapter.apply(ChunkNavigationRequest.from_delta(chunk_delta))
	if not navigation_result.is_success():
		return false
	if not maintain_creatures():
		return false
	if not chunk_discovery_adapter.observe_center(chunk_delta.center).is_success():
		return false
	chunk_debug_overlay.render_snapshot(chunk_admission.create_debug_snapshot())
	return true

var _audio_tick := 0.0


func _tick_audio_director(progress: float, weather: int, delta: float) -> void:
	_audio_tick += delta
	if _audio_tick < 1.0:
		return
	_audio_tick = 0.0
	if AudioDirector.instance == null:
		return
	var danger := night_raid_state.lifecycle_id == NightRaidState.ACTIVE \
		or world_boss_state.lifecycle_id == WorldBossState.ACTIVE
	var ctx := MusicContext.snapshot(
		TownDistrictDB.district_at(player.global_position),
		WorldClock.phase_name(WorldClock.phase_for_progress(progress)),
		weather,
		danger
	)
	(AudioDirector.instance as Node).update_context(ctx)


func _build_town_for_delta(chunk_delta: ChunkAdmissionDelta) -> void:	if town_builder == null:
		return
	for key in chunk_delta.admitted_keys:
		var chunk_node := chunk_scene_adapter.get_node_for_key(key)
		if chunk_node == null:
			continue
		var parsed: Array[Vector2i] = []
		if ChunkCoordinate.try_parse_key(key, parsed):
			town_builder.build_for_chunk(chunk_node, parsed[0])


func toggle_chunk_debug_overlay() -> bool:
	return chunk_debug_overlay.toggle() if is_instance_valid(chunk_debug_overlay) else false


func toggle_minimap() -> bool:
	if minimap_panel == null or not is_instance_valid(minimap_panel):
		return false
	if not minimap_panel.is_open():
		minimap_panel.render_snapshot(get_chunk_discovery_view_snapshot())
	return minimap_panel.toggle()


func _on_minimap_travel_requested(destination_id: StringName) -> void:
	if minimap_panel == null or not is_instance_valid(minimap_panel):
		return
	var result := try_fast_travel(destination_id)
	minimap_panel.show_travel_result(result)
	minimap_panel.render_snapshot(get_chunk_discovery_view_snapshot())


func is_fast_travel_encounter_blocked() -> bool:
	if night_raid_state.lifecycle_id == NightRaidState.ACTIVE:
		return true
	if world_boss_state.lifecycle_id == WorldBossState.ACTIVE:
		return true
	for child in creature_container.get_children():
		if child == null or not is_instance_valid(child):
			continue
		var hp_value: Variant = child.get("hp")
		if child.get("target") == player and hp_value != null and int(hp_value) > 0:
			return true
	return false


## Atomic fast-travel command: pure policy resolves first, then cost is spent
## via inventory transaction and the player is teleported through the normal
## chunk admission pipeline. If admission fails, the cost is refunded and the
## player is restored; no partial teleport is ever committed.
func try_fast_travel(destination_id: StringName) -> FastTravelResult:
	var now_msec := Time.get_ticks_msec()
	var counts := {
		FastTravelPolicy.COST_ITEM_ID: InventoryTransaction.new(player.get("inventory")).get_count(FastTravelPolicy.COST_ITEM_ID),
	}
	var request := FastTravelRequest.new(destination_id, chunk_discovery_adapter.state.revision)
	var planned := FastTravelPolicy.resolve(
		request,
		chunk_discovery_adapter.state,
		ChunkCoordinate.to_key(chunk_admission.center),
		counts,
		is_fast_travel_encounter_blocked(),
		fast_travel_cooldown_until_msec,
		now_msec
	)
	if not planned.is_success():
		return planned
	var previous_position := player.global_position
	var spend := InventoryTransaction.new(player.get("inventory")).remove(planned.cost_item_id, planned.cost_amount)
	if not spend.is_success():
		return FastTravelResult.new(
			FastTravelResult.Status.COMMIT_FAILED,
			planned.destination_id, planned.chunk_key, planned.landing_position,
			planned.cost_item_id, planned.cost_amount, planned.discovery_revision
		)
	player.global_position = planned.landing_position
	player.velocity = Vector2.ZERO
	if not update_chunk_admission(player.global_position):
		player.global_position = previous_position
		player.velocity = Vector2.ZERO
		InventoryTransaction.new(player.get("inventory")).add(planned.cost_item_id, planned.cost_amount)
		update_chunk_admission(previous_position)
		return FastTravelResult.new(
			FastTravelResult.Status.COMMIT_FAILED,
			planned.destination_id, planned.chunk_key, planned.landing_position,
			planned.cost_item_id, planned.cost_amount, planned.discovery_revision
		)
	fast_travel_cooldown_until_msec = now_msec + FastTravelPolicy.COOLDOWN_MSEC
	return planned

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			toggle_chunk_debug_overlay()
		elif event.keycode == KEY_M:
			toggle_minimap()
		elif event.keycode == KEY_F5:
			var quicksave := save_game_to_slot(current_save_slot, int(Time.get_unix_time_from_system()))
			hud.show_banner(Localization.text("slots.quicksaved") if quicksave.is_success() else Localization.text("slots.quicksave_failed"), 2.0)
		elif event.keycode == KEY_F9:
			toggle_save_slots()
		elif event.keycode == KEY_F10:
			toggle_settings()

func _exit_tree() -> void:
	if ambient_spawn_adapter != null: ambient_spawn_adapter.cleanup()
	if chunk_navigation_adapter != null: chunk_navigation_adapter.cleanup()
	if chunk_scene_adapter != null: chunk_scene_adapter.cleanup()

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

func maintain_creatures() -> bool:
	if ambient_spawn_adapter == null: return false
	ambient_spawn_adapter.world_clock_seconds = day_time
	var time_bucket := clampi(floori(fmod(day_time / day_duration, 1.0) * 4.0), 0, 3)
	var request := ambient_spawn_adapter.create_request(
		chunk_admission.center,
		chunk_admission.get_active_keys(),
		WorldChunkCatalog.DEFAULT_BIOME_ID,
		time_bucket,
		max_wild_creatures,
		730201,
		chunk_admission.revision
	)
	return ambient_spawn_adapter.reconcile(request).is_success()
