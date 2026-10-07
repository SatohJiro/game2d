extends StaticBody2D
class_name ResourceNode

enum NodeType { TREE, ROCK, FARM_PLOT }
@export var node_type: NodeType = NodeType.TREE
@export var resource_instance_id: StringName = &""

var max_health: int = 60
var health: int = 60
var respawn_remaining: float = 0.0

# Farm plot state
enum CropStage { EMPTY, SEEDED, GROWING, READY }
enum CropType { BERRY, WHEAT, HERB }
var crop_stage: CropStage = CropStage.EMPTY
var crop_type: CropType = CropType.BERRY
var grow_timer: float = 0.0
var moisture: float = 0.0
var is_watered: bool = false
var is_fertilized: bool = false

@onready var visual: Node2D = $Visual
@onready var label: Label = $Label
@onready var soil_sprite: Sprite2D = $Visual/FarmSoil
@onready var crop_sprite: Sprite2D = $Visual/CropSprite

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const DROPPED_ITEM_SCENE = preload("res://scenes/dropped_item.tscn")

const TEX_BERRY = preload("res://assets/items/berry.png")
const TEX_WHEAT = preload("res://assets/items/wheat_crop.png")
const TEX_HERB = preload("res://assets/items/pal_herb.png")
const TEX_CROP_STAGES = preload("res://assets/items/crop_stages.png")

func _ready() -> void:
	add_to_group("resource_nodes")
	setup_node()

func setup_node() -> void:
	if label:
		label.visible = false
	
	if has_node("InteractionArea"):
		var area = $InteractionArea
		if not area.body_entered.is_connected(_on_interact_body_entered):
			area.body_entered.connect(_on_interact_body_entered)
			area.body_exited.connect(_on_interact_body_exited)
	
	match node_type:
		NodeType.TREE:
			max_health = 60
			health = max_health
			$Visual/TreeSprite.texture = preload("res://assets/tilesets/nature_tree_oak.png")
			$Visual/TreeSprite.visible = true
			$Visual/RockSprite.visible = false
			$Visual/FarmSoil.visible = false
			$Visual/CropSprite.visible = false
		NodeType.ROCK:
			max_health = 80
			health = max_health
			$Visual/TreeSprite.visible = false
			if randf() < 0.5:
				$Visual/RockSprite.texture = preload("res://assets/tilesets/pal_crystal_ore.png")
			else:
				$Visual/RockSprite.texture = preload("res://assets/tilesets/nature_boulder.png")
			$Visual/RockSprite.visible = true
			$Visual/FarmSoil.visible = false
			$Visual/CropSprite.visible = false
		NodeType.FARM_PLOT:
			max_health = 9999
			health = max_health
			$Visual/TreeSprite.visible = false
			$Visual/RockSprite.visible = false
			$Visual/FarmSoil.visible = true
			$Visual/CropSprite.visible = false
			update_farm_display()

func _on_interact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and node_type == NodeType.FARM_PLOT and label:
		label.visible = true
		update_farm_display()

func _on_interact_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and node_type == NodeType.FARM_PLOT and label:
		label.visible = false

func _process(delta: float) -> void:
	if node_type == NodeType.TREE and respawn_remaining > 0.0:
		respawn_remaining = maxf(0.0, respawn_remaining - delta)
		if is_zero_approx(respawn_remaining):
			_restore_resource_without_rewards()
	# Subtle natural wind swaying
	if node_type == NodeType.TREE and has_node("Visual/TreeSprite"):
		$Visual/TreeSprite.rotation = sin(Time.get_ticks_msec() * 0.0018 + global_position.x * 0.05) * 0.025
	elif node_type == NodeType.FARM_PLOT and crop_stage != CropStage.EMPTY and crop_sprite:
		crop_sprite.rotation = sin(Time.get_ticks_msec() * 0.0035 + global_position.x * 0.1) * 0.05
	
	if node_type == NodeType.FARM_PLOT:
		# Process moisture loss over time
		if moisture > 0.0:
			moisture = max(0.0, moisture - delta * 1.5)
			var was_watered = is_watered
			is_watered = moisture > 0.0
			if was_watered != is_watered:
				update_farm_display()
		
		if crop_stage != CropStage.EMPTY and crop_stage != CropStage.READY:
			var speed_mult = (2.5 if is_watered else 1.0) * (1.5 if is_fertilized else 1.0)
			grow_timer += delta * speed_mult
			if crop_stage == CropStage.SEEDED and grow_timer >= 4.5:
				crop_stage = CropStage.GROWING
				animate_growth_pop()
				update_farm_display()
			elif crop_stage == CropStage.GROWING and grow_timer >= 10.0:
				crop_stage = CropStage.READY
				animate_growth_pop()
				update_farm_display()

func animate_growth_pop() -> void:
	if not crop_sprite: return
	var tw = create_tween()
	tw.tween_property(crop_sprite, "scale", crop_sprite.scale * 1.35, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(crop_sprite, "scale", crop_sprite.scale, 0.15)

func hit_by_tool(amount: int, player_ref: Node2D) -> void:
	if node_type == NodeType.FARM_PLOT:
		interact(player_ref)
		return
	
	health -= amount
	health = max(0, health)
	
	if AudioManager:
		AudioManager.play_sound("hit")
	
	if node_type == NodeType.TREE:
		# Organic spring tilt wobble
		var tween = create_tween()
		tween.tween_property(visual, "rotation", 0.14, 0.05).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(visual, "rotation", -0.10, 0.07)
		tween.tween_property(visual, "rotation", 0.05, 0.06)
		tween.tween_property(visual, "rotation", 0.0, 0.06)
		
		# Spawn falling leaf particle
		spawn_leaf_particle()
		
		# Spawn physical wood pickup items that bounce out
		var drop_count = randi_range(1, 2)
		for i in range(drop_count):
			spawn_dropped_item("Gỗ", 2)
		
		if randf() < 0.35:
			spawn_dropped_item("Hạt Giống Cây", 1)
	
	elif node_type == NodeType.ROCK:
		# Squash and stretch impact
		var tween = create_tween()
		tween.tween_property(visual, "scale", Vector2(1.22, 0.82), 0.05).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(visual, "scale", Vector2(0.92, 1.12), 0.07)
		tween.tween_property(visual, "scale", Vector2.ONE, 0.08)
		
		# Spawn spark particles
		spawn_spark_particle()
		
		# Spawn physical stone/ore pickup items
		spawn_dropped_item("Đá", 2)
		if randf() < 0.55:
			spawn_dropped_item("Quặng Pal", 1)
	
	if health <= 0:
		break_resource(player_ref)

func spawn_leaf_particle() -> void:
	if not is_inside_tree(): return
	var leaf = Sprite2D.new()
	leaf.texture = preload("res://assets/fx/leaf.png")
	leaf.global_position = global_position + Vector2(randf_range(-15, 15), -45)
	get_parent().add_child(leaf)
	
	var tween = create_tween()
	var dest = leaf.global_position + Vector2(randf_range(-20, 20), 40)
	tween.tween_property(leaf, "global_position", dest, 0.6).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(leaf, "rotation", randf_range(-2.0, 2.0), 0.6)
	tween.parallel().tween_property(leaf, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(leaf.queue_free)

func spawn_spark_particle() -> void:
	if not is_inside_tree(): return
	var spark = Sprite2D.new()
	spark.texture = preload("res://assets/fx/spark.png")
	spark.global_position = global_position + Vector2(randf_range(-10, 10), -8)
	get_parent().add_child(spark)
	
	var tween = create_tween()
	var dest = spark.global_position + Vector2(randf_range(-25, 25), randf_range(-25, -5))
	tween.tween_property(spark, "global_position", dest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(spark, "scale", Vector2(0.3, 0.3), 0.28)
	tween.chain().tween_callback(spark.queue_free)

func spawn_dropped_item(item_name: String, count: int) -> void:
	if not is_inside_tree(): return
	var item = DROPPED_ITEM_SCENE.instantiate()
	item.item_name = item_name
	item.item_id = LegacyItemAdapter.to_content_id(item_name)
	item.count = count
	item.global_position = global_position + Vector2(randf_range(-8, 8), 0)
	get_parent().call_deferred("add_child", item)

func break_resource(player_ref: Node2D) -> void:
	spawn_floating_text("ĐÃ KHAI THÁC!", Color(1.0, 0.9, 0.2))
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Extra bonus drops on break
	if node_type == NodeType.TREE:
		spawn_dropped_item("Gỗ", 3)
	elif node_type == NodeType.ROCK:
		spawn_dropped_item("Đá", 3)
		spawn_dropped_item("Quặng Pal", 2)
	
	if node_type == NodeType.TREE:
		respawn_remaining = ResourceDepletionState.RESPAWN_SECONDS
	else:
		await get_tree().create_timer(18.0).timeout
		_restore_resource_without_rewards()

func _restore_resource_without_rewards() -> void:
	health = max_health
	$CollisionShape2D.set_deferred("disabled", false)
	var respawn_tween = create_tween()
	respawn_tween.tween_property(visual, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func create_resource_depletion_record() -> ResourceDepletionRecord:
	if node_type != NodeType.TREE or resource_instance_id.is_empty(): return null
	return ResourceDepletionRecord.new(resource_instance_id, ResourceDepletionRecord.TREE_ID, ResourceDepletionState.new(health, respawn_remaining))

func apply_resource_depletion_state(state: ResourceDepletionState) -> bool:
	if node_type != NodeType.TREE or state == null or not state.is_valid(): return false
	health = state.health
	respawn_remaining = state.respawn_remaining
	var depleted := health == 0
	visual.scale = Vector2.ZERO if depleted else Vector2.ONE
	$CollisionShape2D.set_deferred("disabled", depleted)
	return true

func interact(player_ref: Node2D) -> void:
	if node_type == NodeType.FARM_PLOT:
		match crop_stage:
			CropStage.EMPTY:
				if not player_ref: return
				
				# Check if player wants to apply fertilizer first
				if not is_fertilized and (player_ref.inventory.get("Phân Bón Hữu Cơ Pal", 0) > 0 or player_ref.inventory.get("Phân Bón Pal", 0) > 0):
					var fert_key = "Phân Bón Hữu Cơ Pal" if player_ref.inventory.get("Phân Bón Hữu Cơ Pal", 0) > 0 else "Phân Bón Pal"
					player_ref.inventory[fert_key] -= 1
					player_ref.update_hud()
					is_fertilized = true
					update_farm_display()
					spawn_floating_text("✨ Đã bón phân hữu cơ (x2 sản lượng)!", Color(0.8, 1.0, 0.3))
					if AudioManager:
						AudioManager.play_sound("powerup")
					return
				
				# Plant crops by priority: Herb > Wheat > Berry
				if player_ref.inventory.get("Hạt Thảo Dược", 0) > 0:
					player_ref.inventory["Hạt Thảo Dược"] -= 1
					crop_type = CropType.HERB
				elif player_ref.inventory.get("Hạt Lúa Mì", 0) > 0:
					player_ref.inventory["Hạt Lúa Mì"] -= 1
					crop_type = CropType.WHEAT
				elif player_ref.inventory.get("Hạt Giống Cây", 0) > 0:
					player_ref.inventory["Hạt Giống Cây"] -= 1
					crop_type = CropType.BERRY
				else:
					spawn_floating_text("Cần Hạt Giống! (Chặt cây / nhổ cỏ để kiếm)", Color(1.0, 0.4, 0.4))
					return
				
				player_ref.update_hud()
				crop_stage = CropStage.SEEDED
				grow_timer = 0.0
				update_farm_display()
				var cname = "Thảo Dược" if crop_type == CropType.HERB else ("Lúa Mì" if crop_type == CropType.WHEAT else "Quả Mọng")
				spawn_floating_text("🌱 Đã gieo hạt [%s]!" % cname, Color(0.4, 0.95, 0.3))
				if AudioManager:
					AudioManager.play_sound("pickup")
				
			CropStage.SEEDED, CropStage.GROWING:
				# Manually water if not watered yet
				if not is_watered:
					water_crop()
				else:
					spawn_floating_text("Cây đang phát triển xanh tốt (Đất ẩm x2.5 tốc độ)...", Color(0.3, 0.9, 1.0))
					
			CropStage.READY:
				var bonus_mult = 2 if is_fertilized else 1
				var drop_name = "Quả Mọng Hồi Máu"
				var seed_name = "Hạt Giống Cây"
				var amount = randi_range(3, 5) * bonus_mult
				
				match crop_type:
					CropType.HERB:
						drop_name = "Thảo Dược Pal"
						seed_name = "Hạt Thảo Dược"
						amount = randi_range(2, 4) * bonus_mult
					CropType.WHEAT:
						drop_name = "Lúa Mì Hoàng Kim"
						seed_name = "Hạt Lúa Mì"
						amount = randi_range(3, 6) * bonus_mult
					CropType.BERRY:
						drop_name = "Quả Mọng Hồi Máu"
						seed_name = "Hạt Giống Cây"
						amount = randi_range(3, 5) * bonus_mult
				
				for i in range(amount):
					spawn_dropped_item(drop_name, 1)
				
				# Seed refund drop for sustainable farming cycle
				spawn_dropped_item(seed_name, randi_range(1, 2))
				
				if AudioManager:
					AudioManager.play_sound("pickup")
				
				var banner_text = "🌾 Thu hoạch: +%d %s!" % [amount, drop_name]
				if is_fertilized:
					banner_text += " [BỘI THU X2!]"
				spawn_floating_text(banner_text, Color(1.0, 0.9, 0.2))
				
				# Harvest leaf burst effect
				for k in range(3):
					spawn_leaf_particle()
				
				crop_stage = CropStage.EMPTY
				is_watered = false
				is_fertilized = false
				update_farm_display()
	else:
		hit_by_tool(25, player_ref)

func water_crop() -> void:
	if node_type == NodeType.FARM_PLOT:
		moisture = 100.0
		is_watered = true
		grow_timer += 2.0
		spawn_water_splashes()
		spawn_floating_text("💧 Tưới nước đẫm đất! (Ẩm 100% - x2.5 tốc độ)", Color(0.3, 0.85, 1.0))
		update_farm_display()
		if AudioManager:
			AudioManager.play_sound("pickup")

func spawn_water_splashes() -> void:
	if not is_inside_tree(): return
	for i in range(4):
		var drop = Sprite2D.new()
		drop.texture = preload("res://assets/fx/spark.png")
		drop.modulate = Color(0.35, 0.75, 1.2)
		drop.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-4, 8))
		get_parent().add_child(drop)
		
		var tw = create_tween()
		var dest = drop.global_position + Vector2(randf_range(-16, 16), randf_range(-20, -6))
		tw.tween_property(drop, "global_position", dest, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(drop, "scale", Vector2(0.3, 0.3), 0.22)
		tw.chain().tween_callback(drop.queue_free)

func update_farm_display() -> void:
	if not label or not soil_sprite or not crop_sprite: return
	
	# Texture mapping according to crop type
	match crop_type:
		CropType.HERB:
			crop_sprite.texture = TEX_HERB
		CropType.WHEAT:
			crop_sprite.texture = TEX_WHEAT
		CropType.BERRY:
			crop_sprite.texture = TEX_BERRY
	
	# Soil appearance: wet or dry, fertilized or normal
	if is_watered:
		var wet_t = clampf(moisture / 100.0, 0.3, 1.0)
		soil_sprite.modulate = Color(0.55, 0.65, 0.95).lerp(Color.WHITE, 1.0 - wet_t)
	elif is_fertilized:
		soil_sprite.modulate = Color(1.15, 1.25, 0.75) # Rich fertilized glow
	else:
		soil_sprite.modulate = Color.WHITE
	
	var fert_tag = " [Phân Bón x2]" if is_fertilized else ""
	var water_tag = " (Ẩm %d%% 💧)" % int(moisture) if is_watered else " (Khô hạn)"
	
	match crop_stage:
		CropStage.EMPTY:
			crop_sprite.visible = false
			label.text = "Đất Cày%s%s [E gieo hạt]" % [fert_tag, water_tag]
		CropStage.SEEDED:
			crop_sprite.visible = true
			crop_sprite.scale = Vector2(0.85, 0.85)
			label.text = "Mầm Cây%s%s [E tưới]" % [fert_tag, water_tag]
		CropStage.GROWING:
			crop_sprite.visible = true
			crop_sprite.scale = Vector2(1.25, 1.25)
			label.text = "Đang Lớn%s%s [E tưới]" % [fert_tag, water_tag]
		CropStage.READY:
			crop_sprite.visible = true
			crop_sprite.scale = Vector2(1.85, 1.85)
			var crop_name = "Thảo Dược" if crop_type == CropType.HERB else ("Lúa Mì" if crop_type == CropType.WHEAT else "Quả Mọng")
			label.text = "★ Chín Rộ: %s%s [E thu hoạch]" % [crop_name, fert_tag]

func create_persistence_state() -> FarmPlotPlacementState:
	if node_type != NodeType.FARM_PLOT: return null
	var stage_ids: Array[StringName] = [FarmPlotCatalog.EMPTY_STAGE, FarmPlotCatalog.SEEDED_STAGE, FarmPlotCatalog.GROWING_STAGE, FarmPlotCatalog.READY_STAGE]
	var crop_id := &"" if crop_stage == CropStage.EMPTY else FarmPlotCatalog.crop_id_from_legacy(int(crop_type))
	return FarmPlotPlacementState.new(stage_ids[int(crop_stage)], crop_id, 0.0 if crop_stage == CropStage.EMPTY else grow_timer, moisture, is_watered, is_fertilized)

func apply_persistence_state(state: FarmPlotPlacementState) -> bool:
	if node_type != NodeType.FARM_PLOT or state == null or not state.is_valid(): return false
	var stages := {FarmPlotCatalog.EMPTY_STAGE: CropStage.EMPTY, FarmPlotCatalog.SEEDED_STAGE: CropStage.SEEDED, FarmPlotCatalog.GROWING_STAGE: CropStage.GROWING, FarmPlotCatalog.READY_STAGE: CropStage.READY}
	crop_stage = stages[state.stage_id]
	if state.crop_id != &"": crop_type = FarmPlotCatalog.legacy_type_from_id(state.crop_id) as CropType
	grow_timer = state.grow_timer; moisture = state.moisture; is_watered = state.is_watered; is_fertilized = state.is_fertilized
	update_farm_display()
	return true

func spawn_floating_text(txt: String, color: Color) -> void:
	var float_node = FLOATING_TEXT_SCENE.instantiate()
	float_node.global_position = global_position + Vector2(randf_range(-12, 12), -30)
	float_node.text = txt
	float_node.color = color
	get_parent().add_child(float_node)
