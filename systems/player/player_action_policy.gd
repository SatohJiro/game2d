class_name PlayerActionPolicy
extends RefCounted


static func is_allowed(intent: PlayerActionIntent, is_building: bool, modal_open: bool, is_rolling: bool) -> bool:
	if intent == null or not intent.is_valid():
		return false
	match intent.action_id:
		PlayerActionIntent.ACTION_BUILD_PLACE, PlayerActionIntent.ACTION_BUILD_CANCEL:
			return is_building
		PlayerActionIntent.ACTION_ROLL:
			return not is_building and not modal_open
		PlayerActionIntent.ACTION_ATTACK:
			return not is_building and not modal_open and not is_rolling
		_:
			return true
