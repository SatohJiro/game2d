class_name FastTravelRequest
extends RefCounted

var destination_id: StringName
var observed_discovery_revision: int


func _init(p_destination_id: StringName, p_observed_discovery_revision: int) -> void:
	destination_id = p_destination_id
	observed_discovery_revision = p_observed_discovery_revision
