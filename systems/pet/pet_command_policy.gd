class_name PetCommandPolicy
extends RefCounted

const CommandResult = preload("res://systems/pet/pet_command_result.gd")

const COMMAND_CYCLE_STANCE := &"pet.command.cycle_stance"
const COMMAND_AUTO_WORK := &"pet.command.auto_work"
const COMMAND_COMBAT_ASSIST := &"pet.command.combat_assist"
const COMMAND_FOLLOW_PROTECT := &"pet.command.follow_protect"
const STANCE_AUTO_WORK := &"pet.stance.auto_work"
const STANCE_COMBAT_ASSIST := &"pet.stance.combat_assist"
const STANCE_FOLLOW_PROTECT := &"pet.stance.follow_protect"
const VALID_STANCES := [STANCE_AUTO_WORK, STANCE_COMBAT_ASSIST, STANCE_FOLLOW_PROTECT]


static func resolve(request: RefCounted) -> RefCounted:
	if request == null or ContentId.domain_of(request.pet_instance_id) != &"pet" or not VALID_STANCES.has(request.current_stance_id):
		return CommandResult.new(CommandResult.Status.INVALID_REQUEST)
	var next_stance := _resolve_target_stance(request.command_id, request.current_stance_id)
	if next_stance.is_empty():
		return CommandResult.new(CommandResult.Status.UNSUPPORTED_COMMAND, request.command_id, request.pet_instance_id, request.current_stance_id)
	if next_stance == request.current_stance_id:
		return CommandResult.new(CommandResult.Status.NO_CHANGE, request.command_id, request.pet_instance_id, request.current_stance_id, next_stance)
	return CommandResult.new(CommandResult.Status.APPLIED, request.command_id, request.pet_instance_id, request.current_stance_id, next_stance)


static func _resolve_target_stance(command_id: StringName, current_stance_id: StringName) -> StringName:
	match command_id:
		COMMAND_CYCLE_STANCE:
			var current_index := VALID_STANCES.find(current_stance_id)
			return VALID_STANCES[(current_index + 1) % VALID_STANCES.size()]
		COMMAND_AUTO_WORK:
			return STANCE_AUTO_WORK
		COMMAND_COMBAT_ASSIST:
			return STANCE_COMBAT_ASSIST
		COMMAND_FOLLOW_PROTECT:
			return STANCE_FOLLOW_PROTECT
	return &""
