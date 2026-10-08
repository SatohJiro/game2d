class_name ChunkAdmissionRequest
extends RefCounted

var center: Vector2i
var active_keys: Array[StringName]
var observed_revision: int


func _init(p_center: Vector2i, p_active_keys: Array[StringName], p_observed_revision: int) -> void:
	center = p_center
	active_keys = p_active_keys.duplicate()
	observed_revision = p_observed_revision
