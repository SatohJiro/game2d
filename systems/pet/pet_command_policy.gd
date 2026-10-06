class_name PetCommandPolicy
extends RefCounted

const CommandResult = preload("res://systems/pet/pet_command_result.gd")

const COMMAND_CYCLE_STANCE := &"pet.command.cycle_stance"
const STANCE_AUTO_WORK := &"pet.stance.auto_work"
const STANCE_COMBAT_ASSIST := &"pet.stance.combat_assist"
const STANCE_FOLLOW_PROTECT := &"pet.stance.follow_protect"
const VALID_STANCES := [STANCE_AUTO_WORK, STANCE_COMBAT_ASSIST, STANCE_FOLLOW_PROTECT]


static func resolve(request: RefCounted) -> RefCounted:
	if request == null or ContentId.domain_of(request.pet_instance_id) != &"pet" or not VALID_STANCES.has(request.current_stance_id):
		return CommandResult.new(CommandResult.Status.INVALID_REQUEST)
	if request.command_id != COMMAND_CYCLE_STANCE:
		return CommandResult.new(CommandResult.Status.UNSUPPORTED_COMMAND, request.command_id, request.pet_instance_id, request.current_stance_id)
	var current_index := VALID_STANCES.find(request.current_stance_id)
	var next_stance: StringName = VALID_STANCES[(current_index + 1) % VALID_STANCES.size()]
	return CommandResult.new(CommandResult.Status.APPLIED, request.command_id, request.pet_instance_id, request.current_stance_id, next_stance)
