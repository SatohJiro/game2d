class_name DamageResult
extends RefCounted

enum Status { OK, INVALID_REQUEST, FRIENDLY_FIRE_BLOCKED, IMMUNE, ALREADY_DEFEATED }

var status: Status
var applied_damage: int
var remaining_hp: int
var defeated: bool
var knockback: Vector2
var tags: PackedStringArray


func _init(
	result_status: Status,
	result_applied_damage: int,
	result_remaining_hp: int,
	result_defeated: bool = false,
	result_knockback: Vector2 = Vector2.ZERO,
	result_tags: PackedStringArray = PackedStringArray()
) -> void:
	status = result_status
	applied_damage = result_applied_damage
	remaining_hp = result_remaining_hp
	defeated = result_defeated
	knockback = result_knockback
	tags = result_tags.duplicate()


func is_applied() -> bool:
	return status == Status.OK
