class_name PlayerNeedsState
extends RefCounted

const BUFF_NONE: StringName = &""
const BUFF_STAMINA_REGEN: StringName = &"needs.buff.stamina_regen"
const BUFF_WARMTH: StringName = &"needs.buff.warmth"
const BUFF_SPEED: StringName = &"needs.buff.speed"
const BUFF_SLOW_HUNGER: StringName = &"needs.buff.slow_hunger"

const DEFAULT_MAX_HUNGER := 100.0
const DEFAULT_MAX_THIRST := 100.0
const COMFORTABLE_TEMPERATURE := 37.0
const AMBIENT_TEMPERATURE := 23.5

var max_hunger: float = DEFAULT_MAX_HUNGER
var hunger: float = DEFAULT_MAX_HUNGER
var max_thirst: float = DEFAULT_MAX_THIRST
var thirst: float = DEFAULT_MAX_THIRST
var body_temperature: float = COMFORTABLE_TEMPERATURE
var buff_id: StringName = BUFF_NONE
var buff_time_remaining: float = 0.0


func tick(delta: float, is_sprinting: bool, near_heat: bool) -> PlayerNeedsTickResult:
	if delta <= 0.0:
		return PlayerNeedsTickResult.new(create_snapshot())
	hunger = maxf(0.0, hunger - delta * get_hunger_drain_rate())
	thirst = maxf(0.0, thirst - delta * get_thirst_drain_rate(is_sprinting))

	var buff_expired := false
	if buff_id != BUFF_NONE:
		buff_time_remaining = maxf(0.0, buff_time_remaining - delta)
		if is_zero_approx(buff_time_remaining):
			clear_buff()
			buff_expired = true

	var has_warmth := near_heat or buff_id == BUFF_WARMTH
	var temperature_target := COMFORTABLE_TEMPERATURE if has_warmth else AMBIENT_TEMPERATURE
	var temperature_rate := 1.5 if has_warmth else 0.15
	body_temperature = move_toward(body_temperature, temperature_target, delta * temperature_rate)
	return PlayerNeedsTickResult.new(create_snapshot(), buff_expired)


func restore_hunger(amount: float) -> void:
	if amount > 0.0:
		hunger = minf(max_hunger, hunger + amount)


func restore_thirst(amount: float) -> void:
	if amount > 0.0:
		thirst = minf(max_thirst, thirst + amount)


func set_hunger(value: float) -> void:
	hunger = clampf(value, 0.0, max_hunger)


func set_thirst(value: float) -> void:
	thirst = clampf(value, 0.0, max_thirst)


func set_max_hunger(value: float) -> void:
	max_hunger = maxf(0.0, value)
	hunger = minf(hunger, max_hunger)


func set_max_thirst(value: float) -> void:
	max_thirst = maxf(0.0, value)
	thirst = minf(thirst, max_thirst)


func set_temperature(value: float) -> void:
	body_temperature = value


func set_buff(new_buff_id: StringName, duration: float) -> void:
	if new_buff_id == BUFF_NONE or duration <= 0.0:
		clear_buff()
		return
	buff_id = new_buff_id
	buff_time_remaining = duration


func set_buff_duration(duration: float) -> void:
	if buff_id == BUFF_NONE or duration <= 0.0:
		clear_buff()
		return
	buff_time_remaining = duration


func clear_buff() -> void:
	buff_id = BUFF_NONE
	buff_time_remaining = 0.0


func get_hunger_drain_rate() -> float:
	return 0.14 if buff_id == BUFF_SLOW_HUNGER else 0.28


func get_thirst_drain_rate(is_sprinting: bool) -> float:
	return 0.45 if is_sprinting else 0.25


func get_movement_multiplier() -> float:
	var multiplier := 1.0
	if thirst < 20.0:
		multiplier *= 0.8
	if body_temperature < 25.0:
		multiplier *= 0.85
	if buff_id == BUFF_SPEED:
		multiplier *= 1.15
	return multiplier


func get_stamina_regen_multiplier() -> float:
	var multiplier := 0.5 if hunger < 20.0 else 1.0
	if buff_id == BUFF_STAMINA_REGEN:
		multiplier *= 1.5
	return multiplier


func get_buff_display_name() -> String:
	match buff_id:
		BUFF_STAMINA_REGEN: return "Bồi Bổ Thể Lực (x1.5 hồi)"
		BUFF_WARMTH: return "Giữ Nhiệt Ấm Áp"
		BUFF_SPEED: return "Tăng Tốc Chạy (+15%)"
		BUFF_SLOW_HUNGER: return "No Lâu Giảm Đói"
		_: return ""


func set_legacy_buff_name(display_name: String) -> void:
	match display_name:
		"Bồi Bổ Thể Lực (x1.5 hồi)": buff_id = BUFF_STAMINA_REGEN
		"Giữ Nhiệt Ấm Áp": buff_id = BUFF_WARMTH
		"Tăng Tốc Chạy (+15%)": buff_id = BUFF_SPEED
		"No Lâu Giảm Đói": buff_id = BUFF_SLOW_HUNGER
		_: clear_buff()


func create_snapshot() -> PlayerNeedsSnapshot:
	return PlayerNeedsSnapshot.new(max_hunger, hunger, max_thirst, thirst, body_temperature, buff_id, buff_time_remaining, get_buff_display_name())
