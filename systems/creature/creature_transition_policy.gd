class_name CreatureTransitionPolicy
extends RefCounted

const STATE_IDLE := &"creature.state.idle"
const STATE_WANDER := &"creature.state.wander"
const STATE_SUSPICIOUS := &"creature.state.suspicious"
const STATE_ALERT := &"creature.state.alert"
const STATE_CHASE := &"creature.state.chase"

const EVENT_IDLE_WANDER := &"creature.transition.idle_wander"
const EVENT_WANDER_COMPLETE := &"creature.transition.wander_complete"
const EVENT_SUSPICION_TIMEOUT := &"creature.transition.suspicion_timeout"
const EVENT_CHASE_TARGET_LOST := &"creature.transition.chase_target_lost"
const EVENT_CHASE_OUT_OF_RANGE := &"creature.transition.chase_out_of_range"

const REASON_SUSPICION_CONFIRMED := &"creature.transition.suspicion_confirmed"
const REASON_SUSPICION_LOST := &"creature.transition.suspicion_lost"

const SUSPICION_CONFIRM_DISTANCE := 140.0
const CHASE_LEASH_DISTANCE := 450.0
const ALERT_TIMER := 0.40
const SUSPICION_LOST_TIMER := 2.0
const CHASE_TARGET_LOST_TIMER := 1.0
const CHASE_OUT_OF_RANGE_TIMER := 2.0


static func resolve(request: CreatureTransitionRequest) -> CreatureTransitionResult:
	if request == null or request.current_state_id.is_empty() or request.event_id.is_empty():
		return CreatureTransitionResult.new(CreatureTransitionResult.Status.INVALID_REQUEST)
	if request.is_protected:
		return CreatureTransitionResult.new(
			CreatureTransitionResult.Status.PROTECTED,
			request.current_state_id
		)
	if not request.condition_met:
		return _no_change(request)

	match request.event_id:
		EVENT_IDLE_WANDER:
			if request.current_state_id != STATE_IDLE:
				return _no_change(request)
			if not _is_positive_finite(request.proposed_timer):
				return _invalid(request)
			return _changed(
				request,
				STATE_WANDER,
				EVENT_IDLE_WANDER,
				request.proposed_timer,
				CreatureTransitionResult.TargetAction.KEEP
			)
		EVENT_WANDER_COMPLETE:
			if request.current_state_id != STATE_WANDER:
				return _no_change(request)
			if not _is_positive_finite(request.proposed_timer):
				return _invalid(request)
			return _changed(
				request,
				STATE_IDLE,
				EVENT_WANDER_COMPLETE,
				request.proposed_timer,
				CreatureTransitionResult.TargetAction.KEEP
			)
		EVENT_SUSPICION_TIMEOUT:
			if request.current_state_id != STATE_SUSPICIOUS:
				return _no_change(request)
			if request.has_target and _is_valid_distance(request.target_distance):
				if request.target_distance < SUSPICION_CONFIRM_DISTANCE:
					return _changed(
						request,
						STATE_ALERT,
						REASON_SUSPICION_CONFIRMED,
						ALERT_TIMER,
						CreatureTransitionResult.TargetAction.KEEP
					)
			return _changed(
				request,
				STATE_WANDER,
				REASON_SUSPICION_LOST,
				SUSPICION_LOST_TIMER,
				CreatureTransitionResult.TargetAction.CLEAR
			)
		EVENT_CHASE_TARGET_LOST:
			if request.current_state_id != STATE_CHASE or request.has_target:
				return _no_change(request)
			return _changed(
				request,
				STATE_IDLE,
				EVENT_CHASE_TARGET_LOST,
				CHASE_TARGET_LOST_TIMER,
				CreatureTransitionResult.TargetAction.CLEAR
			)
		EVENT_CHASE_OUT_OF_RANGE:
			if (
				request.current_state_id != STATE_CHASE
				or not request.has_target
				or request.is_night_raider
				or not _is_valid_distance(request.target_distance)
				or request.target_distance <= CHASE_LEASH_DISTANCE
			):
				return _no_change(request)
			return _changed(
				request,
				STATE_IDLE,
				EVENT_CHASE_OUT_OF_RANGE,
				CHASE_OUT_OF_RANGE_TIMER,
				CreatureTransitionResult.TargetAction.CLEAR
			)
		_:
			return _invalid(request)


static func _changed(
	request: CreatureTransitionRequest,
	to_state_id: StringName,
	reason_id: StringName,
	next_timer: float,
	target_action: CreatureTransitionResult.TargetAction
) -> CreatureTransitionResult:
	return CreatureTransitionResult.new(
		CreatureTransitionResult.Status.CHANGED,
		request.current_state_id,
		to_state_id,
		reason_id,
		next_timer,
		target_action
	)


static func _no_change(request: CreatureTransitionRequest) -> CreatureTransitionResult:
	return CreatureTransitionResult.new(
		CreatureTransitionResult.Status.NO_CHANGE,
		request.current_state_id,
		request.current_state_id
	)


static func _invalid(request: CreatureTransitionRequest) -> CreatureTransitionResult:
	return CreatureTransitionResult.new(
		CreatureTransitionResult.Status.INVALID_REQUEST,
		request.current_state_id
	)


static func _is_positive_finite(value: float) -> bool:
	return value > 0.0 and is_finite(value)


static func _is_valid_distance(value: float) -> bool:
	return value >= 0.0 and is_finite(value)
