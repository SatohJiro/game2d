class_name CreatureTransitionPolicy
extends RefCounted

const STATE_IDLE := &"creature.state.idle"
const STATE_WANDER := &"creature.state.wander"
const STATE_SUSPICIOUS := &"creature.state.suspicious"
const STATE_ALERT := &"creature.state.alert"
const STATE_CHASE := &"creature.state.chase"
const STATE_SLEEP := &"creature.state.sleep"
const STATE_DRINKING := &"creature.state.drinking"
const STATE_GRAZING := &"creature.state.grazing"
const STATE_FLEE := &"creature.state.flee"
const STATE_CAPTURING := &"creature.state.capturing"
const STATE_HUNTING_PREY := &"creature.state.hunting_prey"

const EVENT_IDLE_WANDER := &"creature.transition.idle_wander"
const EVENT_WANDER_COMPLETE := &"creature.transition.wander_complete"
const EVENT_SUSPICION_TIMEOUT := &"creature.transition.suspicion_timeout"
const EVENT_CHASE_TARGET_LOST := &"creature.transition.chase_target_lost"
const EVENT_CHASE_OUT_OF_RANGE := &"creature.transition.chase_out_of_range"
const EVENT_PERCEPTION_SUSPICIOUS := &"creature.transition.perception_suspicious"
const EVENT_PERCEPTION_ALERT := &"creature.transition.perception_alert"
const EVENT_SLEEP_COMPLETE := &"creature.transition.sleep_complete"
const EVENT_DRINKING_COMPLETE := &"creature.transition.drinking_complete"
const EVENT_GRAZING_COMPLETE := &"creature.transition.grazing_complete"
const EVENT_ALERT_COMPLETE := &"creature.transition.alert_complete"
const EVENT_FLEE_COMPLETE := &"creature.transition.flee_complete"
const EVENT_FLEE_TARGET_LOST := &"creature.transition.flee_target_lost"
const EVENT_CAPTURE_REJECTED := &"creature.transition.capture_rejected"
const EVENT_ECOLOGY_DAMAGE_PANIC := &"creature.transition.ecology_damage_panic"
const EVENT_ECOLOGY_PREY_ACQUIRED := &"creature.transition.ecology_prey_acquired"
const EVENT_ECOLOGY_GRAZING_ENTRY := &"creature.transition.ecology_grazing_entry"
const EVENT_ECOLOGY_HUNT_ABORTED := &"creature.transition.ecology_hunt_aborted"
const EVENT_ECOLOGY_HUNT_CONTACT := &"creature.transition.ecology_hunt_contact"
const EVENT_ECOLOGY_PREDATOR_THREAT := &"creature.transition.ecology_predator_threat"
const EVENT_ECOLOGY_SLEEP_ENTRY := &"creature.transition.ecology_sleep_entry"

const REASON_SUSPICION_CONFIRMED := &"creature.transition.suspicion_confirmed"
const REASON_SUSPICION_LOST := &"creature.transition.suspicion_lost"

const SUSPICION_CONFIRM_DISTANCE := 140.0
const CHASE_LEASH_DISTANCE := 450.0
const ALERT_TIMER := 0.40
const SUSPICION_LOST_TIMER := 2.0
const CHASE_TARGET_LOST_TIMER := 1.0
const CHASE_OUT_OF_RANGE_TIMER := 2.0
const SLEEP_ENTRY_DURATION_MIN := 6.0
const SLEEP_ENTRY_DURATION_MAX := 11.0


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
		EVENT_PERCEPTION_SUSPICIOUS:
			if request.current_state_id == STATE_SUSPICIOUS or not _is_perception_entry_state(request.current_state_id) or not _has_valid_target(request):
				return _no_change(request)
			return _changed(request, STATE_SUSPICIOUS, EVENT_PERCEPTION_SUSPICIOUS, 1.6, CreatureTransitionResult.TargetAction.SET)
		EVENT_PERCEPTION_ALERT:
			if not _is_perception_entry_state(request.current_state_id) or not _has_valid_target(request):
				return _no_change(request)
			return _changed(request, STATE_ALERT, EVENT_PERCEPTION_ALERT, ALERT_TIMER, CreatureTransitionResult.TargetAction.SET)
		EVENT_SLEEP_COMPLETE:
			return _natural_timeout(request, STATE_SLEEP, EVENT_SLEEP_COMPLETE, 2.0)
		EVENT_DRINKING_COMPLETE:
			return _natural_timeout(request, STATE_DRINKING, EVENT_DRINKING_COMPLETE, 2.5)
		EVENT_GRAZING_COMPLETE:
			return _natural_timeout(request, STATE_GRAZING, EVENT_GRAZING_COMPLETE, 2.0)
		EVENT_ALERT_COMPLETE:
			if request.current_state_id != STATE_ALERT:
				return _no_change(request)
			if request.has_target:
				return _changed(request, STATE_CHASE, EVENT_ALERT_COMPLETE, 0.0, CreatureTransitionResult.TargetAction.KEEP)
			return _changed(request, STATE_IDLE, EVENT_ALERT_COMPLETE, 1.0, CreatureTransitionResult.TargetAction.CLEAR)
		EVENT_FLEE_COMPLETE:
			if request.current_state_id != STATE_FLEE:
				return _no_change(request)
			return _changed(request, STATE_IDLE, EVENT_FLEE_COMPLETE, 2.0, CreatureTransitionResult.TargetAction.CLEAR)
		EVENT_FLEE_TARGET_LOST:
			if request.current_state_id != STATE_FLEE or request.has_target:
				return _no_change(request)
			return _changed(request, STATE_IDLE, EVENT_FLEE_TARGET_LOST, 1.0, CreatureTransitionResult.TargetAction.CLEAR)
		EVENT_CAPTURE_REJECTED:
			if request.current_state_id != STATE_CAPTURING:
				return _no_change(request)
			if _has_valid_target(request):
				return _changed(request, STATE_CHASE, EVENT_CAPTURE_REJECTED, 0.0, CreatureTransitionResult.TargetAction.SET)
			return _changed(request, STATE_IDLE, EVENT_CAPTURE_REJECTED, 0.0, CreatureTransitionResult.TargetAction.CLEAR)
		EVENT_ECOLOGY_DAMAGE_PANIC:
			if not _is_positive_finite(request.proposed_timer):
				return _invalid(request)
			return _changed(request, STATE_FLEE, EVENT_ECOLOGY_DAMAGE_PANIC, request.proposed_timer, CreatureTransitionResult.TargetAction.KEEP)
		EVENT_ECOLOGY_PREY_ACQUIRED:
			if not _is_positive_finite(request.proposed_timer):
				return _invalid(request)
			return _changed(request, STATE_HUNTING_PREY, EVENT_ECOLOGY_PREY_ACQUIRED, request.proposed_timer, CreatureTransitionResult.TargetAction.KEEP)
		EVENT_ECOLOGY_GRAZING_ENTRY:
			if request.current_state_id != STATE_IDLE:
				return _no_change(request)
			if not _is_positive_finite(request.proposed_timer):
				return _invalid(request)
			return _changed(request, STATE_GRAZING, EVENT_ECOLOGY_GRAZING_ENTRY, request.proposed_timer, CreatureTransitionResult.TargetAction.KEEP)
		EVENT_ECOLOGY_HUNT_ABORTED:
			if request.current_state_id != STATE_HUNTING_PREY:
				return _no_change(request)
			return _changed(request, STATE_IDLE, EVENT_ECOLOGY_HUNT_ABORTED, 2.0, CreatureTransitionResult.TargetAction.KEEP)
		EVENT_ECOLOGY_HUNT_CONTACT:
			if request.current_state_id != STATE_HUNTING_PREY:
				return _no_change(request)
			return _changed(request, STATE_IDLE, EVENT_ECOLOGY_HUNT_CONTACT, 3.0, CreatureTransitionResult.TargetAction.KEEP)
		EVENT_ECOLOGY_PREDATOR_THREAT:
			if request.current_state_id == STATE_FLEE or request.current_state_id == STATE_CAPTURING or not _has_valid_target(request):
				return _no_change(request)
			return _changed(request, STATE_FLEE, EVENT_ECOLOGY_PREDATOR_THREAT, 4.0, CreatureTransitionResult.TargetAction.SET)
		EVENT_ECOLOGY_SLEEP_ENTRY:
			if request.current_state_id != STATE_IDLE:
				return _no_change(request)
			if not is_finite(request.proposed_timer) or request.proposed_timer < SLEEP_ENTRY_DURATION_MIN or request.proposed_timer > SLEEP_ENTRY_DURATION_MAX:
				return _invalid(request)
			return _changed(request, STATE_SLEEP, EVENT_ECOLOGY_SLEEP_ENTRY, request.proposed_timer, CreatureTransitionResult.TargetAction.KEEP)
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


static func _has_valid_target(request: CreatureTransitionRequest) -> bool:
	return request.has_target and _is_valid_distance(request.target_distance)


static func _is_perception_entry_state(state_id: StringName) -> bool:
	return state_id in [STATE_IDLE, STATE_WANDER, STATE_SUSPICIOUS, STATE_SLEEP, STATE_DRINKING, STATE_GRAZING, STATE_HUNTING_PREY]


static func _natural_timeout(
	request: CreatureTransitionRequest,
	expected_state_id: StringName,
	reason_id: StringName,
	next_timer: float
) -> CreatureTransitionResult:
	if request.current_state_id != expected_state_id:
		return _no_change(request)
	return _changed(request, STATE_IDLE, reason_id, next_timer, CreatureTransitionResult.TargetAction.KEEP)
