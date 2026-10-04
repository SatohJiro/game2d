class_name DamageRequest
extends RefCounted

var source_faction: StringName
var target_faction: StringName
var current_hp: int
var max_hp: int
var base_damage: int
var damage_multiplier: float = 1.0
var defense: int = 0
var hit_origin: Vector2
var target_position: Vector2
var knockback_strength: float = 0.0
var tags: PackedStringArray = PackedStringArray()
var allow_friendly_fire: bool = false
var immune: bool = false


func _init(
	request_source_faction: StringName,
	request_target_faction: StringName,
	request_current_hp: int,
	request_max_hp: int,
	request_base_damage: int,
	request_hit_origin: Vector2 = Vector2.ZERO,
	request_target_position: Vector2 = Vector2.ZERO
) -> void:
	source_faction = request_source_faction
	target_faction = request_target_faction
	current_hp = request_current_hp
	max_hp = request_max_hp
	base_damage = request_base_damage
	hit_origin = request_hit_origin
	target_position = request_target_position
