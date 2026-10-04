class_name PlayerNeedsSnapshot
extends RefCounted

var max_hunger: float
var hunger: float
var max_thirst: float
var thirst: float
var body_temperature: float
var buff_id: StringName
var buff_time_remaining: float
var buff_display_name: String


func _init(initial_max_hunger: float, initial_hunger: float, initial_max_thirst: float, initial_thirst: float, initial_body_temperature: float, initial_buff_id: StringName, initial_buff_time_remaining: float, initial_buff_display_name: String) -> void:
	max_hunger = initial_max_hunger
	hunger = initial_hunger
	max_thirst = initial_max_thirst
	thirst = initial_thirst
	body_temperature = initial_body_temperature
	buff_id = initial_buff_id
	buff_time_remaining = initial_buff_time_remaining
	buff_display_name = initial_buff_display_name
