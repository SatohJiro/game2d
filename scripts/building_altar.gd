extends StaticBody2D
class_name BuildingAltar

@export var max_health: int = 1000
var health: int = 1000

var is_boss_active: bool = false
var boss_instance_id: StringName = &""
var boss_node: Node = null
var _restored_boss_hp: int = AltarPlacementState.BOSS_MAX_HP
@onready var visual: Sprite2D = $Sprite2D
@onready var label: Label = $Label

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const CREATURE_SCENE = preload("res://scenes/creature.tscn")

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("altars")
	health = max_health
	update_display()
	if is_boss_active:
		_spawn_boss(false, boss_instance_id, _restored_boss_hp)

func interact(player: CharacterBody2D) -> void:
	if is_boss_active:
		spawn_floating_text("Trận chiến Boss đang diễn ra!", Color(1.0, 0.4, 0.4))
		return
	
	# Check offering: 3 Thỏi Pal hoặc 5 Quả Mọng
	var pal_ingots = player.inventory.get("Thỏi Pal", 0)
	var berries = player.inventory.get("Quả Mọng Hồi Máu", 0)
	
	if pal_ingots >= 2 or berries >= 6:
		if pal_ingots >= 2:
			player.inventory["Thỏi Pal"] -= 2
		else:
			player.inventory["Quả Mọng Hồi Máu"] -= 6
		player.update_hud()
		
		summon_boss(player)
	else:
		spawn_floating_text("Cần 2 Thỏi Pal hoặc 6 Quả Mọng để tế lễ triệu hồi!", Color(1.0, 0.6, 0.2))

func summon_boss(player: CharacterBody2D) -> void:
	is_boss_active = true
	boss_instance_id = StringName("boss.instance_%d" % ResourceUID.create_id())
	update_display()
	
	if AudioManager:
		AudioManager.play_sound("level_up")
	
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		huds[0].show_banner("⚡ TẾ LỄ HOÀN TẤT: VUA NẤM RỪNG SÂU (BOSS LV.5) ĐÃ THỨC TỈNH!", 6.0)
	
	_spawn_boss(true, boss_instance_id, AltarPlacementState.BOSS_MAX_HP)

func _spawn_boss(show_completion_banner: bool, instance_id: StringName, restored_hp: int) -> void:
	if not is_inside_tree() or is_instance_valid(boss_node): return
	var boss = CREATURE_SCENE.instantiate()
	boss.global_position = global_position + Vector2(100, 60)
	boss.species_index = 2 # Mushroom
	boss.level = 5
	boss.scale = Vector2(2.2, 2.2)
	boss.set_meta("boss_instance_id", instance_id)
	boss.set_meta("altar_instance_id", get_meta("building_instance_id", &""))
	boss.add_to_group("persistent_altar_bosses")
	get_parent().add_child(boss)
	boss_node = boss
	boss.max_hp = AltarPlacementState.BOSS_MAX_HP
	boss.hp = restored_hp
	boss.attack_power = 22
	boss.update_overhead()
	
	# Listen for death to reset altar
	boss.tree_exited.connect(func():
		if bool(boss.get_meta("suppress_altar_lifecycle", false)): return
		is_boss_active = false
		boss_instance_id = &""
		boss_node = null
		update_display()
		var completion_huds = get_tree().get_nodes_in_group("hud") if is_inside_tree() else []
		if show_completion_banner and completion_huds.size() > 0:
			completion_huds[0].show_banner("🏆 CHÚC MỪNG: VUA NẤM ĐÃ BỊ ĐÁNH BẠI! CĂN CỨ ĐẠT TIẾN TRÌNH MỚI!", 6.0)
	)

func create_persistence_state() -> AltarPlacementState:
	if not is_boss_active: return AltarPlacementState.new()
	var current_hp := int(boss_node.get("hp")) if is_instance_valid(boss_node) else _restored_boss_hp
	return AltarPlacementState.new(AltarPlacementState.ACTIVE, boss_instance_id, current_hp)

func apply_persistence_state(state: AltarPlacementState) -> bool:
	if state == null or not state.is_valid(): return false
	is_boss_active = state.lifecycle_id == AltarPlacementState.ACTIVE
	boss_instance_id = state.boss_instance_id
	_restored_boss_hp = state.boss_hp if is_boss_active else AltarPlacementState.BOSS_MAX_HP
	if is_inside_tree() and is_boss_active: _spawn_boss(false, boss_instance_id, _restored_boss_hp)
	return true

func update_display() -> void:
	if not label: return
	if is_boss_active:
		label.text = "⚡ Bệ Tế Lễ [Đang Thức Tỉnh]"
	else:
		label.text = "Bệ Triệu Hồi Boss [E]\n(2 Thỏi Pal / 6 Quả Mọng)"

func spawn_floating_text(text: String, color: Color) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.global_position = global_position + Vector2(0, -32)
	get_parent().add_child(ft)
	ft.set_text(text, color)
