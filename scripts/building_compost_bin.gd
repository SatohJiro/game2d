extends StaticBody2D
class_name BuildingCompostBin

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var label: Label = $Label
@onready var interaction_area: Area2D = $InteractionArea

var organic_materials: int = 0
var max_materials: int = 10
var composting_timer: float = 0.0
var composting_time_per_batch: float = 8.0
var ready_fertilizer_count: int = 0

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const DROPPED_ITEM_SCENE = preload("res://scenes/dropped_item.tscn")

func _ready() -> void:
	add_to_group("compost_bins")
	label.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = true
		update_label_text()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		label.visible = false

func _process(delta: float) -> void:
	if organic_materials > 0:
		composting_timer += delta
		# Breathing organic bubbling movement
		visual.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.04
		
		if composting_timer >= composting_time_per_batch:
			composting_timer = 0.0
			organic_materials -= 1
			ready_fertilizer_count += 1
			spawn_floating_text("♻️ ĐÃ Ủ XONG 1 TÚI PHÂN BÓN!", Color(0.4, 1.0, 0.5))
			if AudioManager:
				AudioManager.play_sound("pickup")
			update_label_text()
	else:
		visual.scale = Vector2.ONE

func interact(player_ref: CharacterBody2D) -> void:
	# Priority 1: Collect finished fertilizer
	if ready_fertilizer_count > 0:
		var collect_amt = ready_fertilizer_count
		ready_fertilizer_count = 0
		player_ref.add_item("Phân Bón Hữu Cơ Pal", collect_amt)
		spawn_floating_text("✨ Thu hoạch +%d Phân Bón Hữu Cơ Pal!" % collect_amt, Color(0.8, 1.0, 0.3))
		if AudioManager:
			AudioManager.play_sound("pickup")
		update_label_text()
		return
	
	# Priority 2: Deposit organic waste (Berries, Wheat, Wood)
	var deposited = false
	if player_ref.inventory.get("Gỗ", 0) >= 2:
		player_ref.inventory["Gỗ"] -= 2
		organic_materials = min(max_materials, organic_materials + 2)
		deposited = true
	elif player_ref.inventory.get("Quả Mọng Hồi Máu", 0) >= 2:
		player_ref.inventory["Quả Mọng Hồi Máu"] -= 2
		organic_materials = min(max_materials, organic_materials + 3)
		deposited = true
	elif player_ref.inventory.get("Lúa Mì Hoàng Kim", 0) >= 1:
		player_ref.inventory["Lúa Mì Hoàng Kim"] -= 1
		organic_materials = min(max_materials, organic_materials + 3)
		deposited = true
	
	if deposited:
		player_ref.update_hud()
		spawn_floating_text("🌿 Đã nạp nguyên liệu hữu cơ vào thùng ủ!", Color(0.5, 0.95, 0.4))
		if AudioManager:
			AudioManager.play_sound("pickup")
		var tw = create_tween()
		tw.tween_property(visual, "scale", Vector2(1.2, 0.8), 0.1)
		tw.tween_property(visual, "scale", Vector2.ONE, 0.15)
	else:
		spawn_floating_text("Cần Gỗ x2 hoặc Quả Mọng x2 để ủ phân!", Color(1.0, 0.4, 0.4))
	
	update_label_text()

func update_label_text() -> void:
	if not label: return
	if ready_fertilizer_count > 0:
		label.text = "Thùng Ủ: [E Nhận x%d Phân Bón!]" % ready_fertilizer_count
		label.modulate = Color(0.4, 1.0, 0.4)
	elif organic_materials > 0:
		label.text = "Thùng Ủ: Đang ủ (Còn %d mẻ)..." % organic_materials
		label.modulate = Color(1.0, 0.9, 0.3)
	else:
		label.text = "Thùng Ủ Phân Hữu Cơ [E nạp nguyên liệu]"
		label.modulate = Color.WHITE


func create_persistence_state() -> CompostBinPlacementState:
	return CompostBinPlacementState.new(organic_materials, ready_fertilizer_count, composting_timer)


func apply_persistence_state(state: CompostBinPlacementState) -> bool:
	if state == null or not state.is_valid():
		return false
	organic_materials = state.organic_materials
	ready_fertilizer_count = state.ready_fertilizer_count
	composting_timer = state.composting_timer
	update_label_text()
	return true

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-10, 10), -30)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)
