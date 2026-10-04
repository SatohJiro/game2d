extends StaticBody2D
class_name BuildingChest

@export var max_health: int = 250
@export_range(1, 100, 1) var inventory_slots: int = 12
var health: int = 250

var stored_items: Dictionary = {
	"Gỗ": 0,
	"Đá": 0,
	"Quặng Pal": 0,
	"Thỏi Sắt": 0,
	"Thỏi Pal": 0,
	"Quả Mọng Hồi Máu": 0
}

@onready var visual: Sprite2D = $Sprite2D
@onready var label: Label = $Label

const FLOATING_TEXT_SCENE = preload("res://scenes/floating_text.tscn")
const WOOD_DEFINITION: ItemDefinition = preload("res://data/definitions/items/wood.tres")
const PAL_ORE_DEFINITION: ItemDefinition = preload("res://data/definitions/items/pal_ore.tres")
const BERRY_DEFINITION: ItemDefinition = preload("res://data/definitions/items/berry.tres")
const MANAGED_ITEM_IDS: Array[StringName] = [&"item.wood", &"item.pal_ore", &"item.berry"]

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("chests")
	health = max_health
	update_display()

func deposit_from_pet(item_name: String, amount: int) -> void:
	var item_id := LegacyItemAdapter.to_content_id(item_name)
	if LegacyItemAdapter.is_mapped(item_id):
		var result := _make_chest_transaction().add(item_id, amount)
		if not result.is_success():
			return
	else:
		if item_name.is_empty() or amount <= 0:
			return
		stored_items[item_name] = maxi(0, int(stored_items.get(item_name, 0))) + amount
	spawn_floating_text("Pet cất +%d %s!" % [amount, item_name], Color(0.4, 1.0, 0.6))
	update_display()

func interact(player: CharacterBody2D) -> void:
	var deposit_result := deposit_mapped_from(player.inventory)
	if deposit_result.is_success():
		spawn_floating_text("Đã cất %d vật phẩm vào rương!" % deposit_result.applied_amount, Color(0.3, 0.9, 1.0))
		player.call("_on_inventory_changed")
	elif deposit_result.status == InventoryTransactionResult.Status.CAPACITY_EXCEEDED:
		spawn_floating_text("Rương không đủ ô trống!", Color(1.0, 0.45, 0.3))
	else:
		var withdraw_result := withdraw_mapped_to(player.inventory, 10)
		if withdraw_result.is_success():
			spawn_floating_text("Rút %d vật phẩm từ rương!" % withdraw_result.applied_amount, Color(1.0, 0.85, 0.3))
			player.call("_on_inventory_changed")
		else:
			spawn_floating_text("Rương đang trống!", Color(0.8, 0.8, 0.8))
	
	update_display()


func deposit_mapped_from(source_store: Dictionary) -> InventoryTransactionResult:
	var amounts := _collect_positive_amounts(source_store, -1)
	if amounts.is_empty():
		return InventoryTransactionResult.new(InventoryTransactionResult.Status.INVALID_AMOUNT, &"", 0)
	return InventoryTransaction.new(source_store).transfer_batch_to(_make_chest_transaction(), amounts)


func withdraw_mapped_to(target_store: Dictionary, max_each: int) -> InventoryTransactionResult:
	var amounts := _collect_positive_amounts(stored_items, max_each)
	if amounts.is_empty():
		return InventoryTransactionResult.new(InventoryTransactionResult.Status.INVALID_AMOUNT, &"", 0)
	return _make_chest_transaction().transfer_batch_to(InventoryTransaction.new(target_store), amounts)


func _make_chest_transaction() -> InventoryTransaction:
	return InventoryTransaction.new(
		stored_items,
		InventoryTransaction.CapacityPolicy.STACK_SLOTS,
		inventory_slots,
		{
			&"item.wood": WOOD_DEFINITION.max_stack,
			&"item.pal_ore": PAL_ORE_DEFINITION.max_stack,
			&"item.berry": BERRY_DEFINITION.max_stack,
		}
	)


func _collect_positive_amounts(store: Dictionary, max_each: int) -> Dictionary:
	var amounts: Dictionary = {}
	for item_id in MANAGED_ITEM_IDS:
		var count := LegacyItemAdapter.get_count(store, item_id)
		if count > 0:
			amounts[item_id] = count if max_each < 0 else mini(count, max_each)
	return amounts

func update_display() -> void:
	if not label: return
	var total = 0
	for count in stored_items.values():
		total += count
	label.text = "Rương Kho Đồ\n[E] Cất/Rút (%d món)" % total

func spawn_floating_text(text: String, color: Color) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.global_position = global_position + Vector2(0, -26)
	get_parent().add_child(ft)
	ft.set_text(text, color)

func take_damage(amount: int) -> void:
	health -= amount
	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1.5, 0.4, 0.4), 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
