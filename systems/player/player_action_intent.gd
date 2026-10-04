class_name PlayerActionIntent
extends RefCounted

const ACTION_NONE: StringName = &""
const ACTION_ATTACK: StringName = &"player.action.attack"
const ACTION_ROLL: StringName = &"player.action.roll"
const ACTION_INTERACT: StringName = &"player.action.interact"
const ACTION_CAPTURE_THROW: StringName = &"player.action.capture_throw"
const ACTION_TOGGLE_CRAFTING: StringName = &"player.action.toggle_crafting"
const ACTION_TOGGLE_CHARACTER: StringName = &"player.action.toggle_character"
const ACTION_BUILD_START: StringName = &"player.action.build_start"
const ACTION_BUILD_PLACE: StringName = &"player.action.build_place"
const ACTION_BUILD_CANCEL: StringName = &"player.action.build_cancel"
const ACTION_PET_SELECT: StringName = &"player.action.pet_select"
const ACTION_PET_COMMAND: StringName = &"player.action.pet_command"
const ACTION_PET_SKILL: StringName = &"player.action.pet_skill"
const ACTION_USE_FOOD: StringName = &"player.action.use_food"
const ACTION_USE_ELIXIR: StringName = &"player.action.use_elixir"

var action_id: StringName
var slot_index: int
var target_id: StringName
var aim_direction: Vector2


func _init(
	initial_action_id: StringName = ACTION_NONE,
	initial_slot_index: int = -1,
	initial_target_id: StringName = &"",
	initial_aim_direction: Vector2 = Vector2.ZERO
) -> void:
	action_id = initial_action_id
	slot_index = initial_slot_index
	target_id = initial_target_id
	aim_direction = initial_aim_direction


func is_valid() -> bool:
	return action_id != ACTION_NONE
