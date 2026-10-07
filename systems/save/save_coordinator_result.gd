class_name SaveCoordinatorResult
extends RefCounted

enum Status { SAVED, LOADED_PRIMARY, LOADED_BACKUP, SNAPSHOT_FAILED, REPOSITORY_FAILED, MIGRATION_FAILED, APPLY_FAILED }

var status: Status
var world_clock_seconds: float
var upstream_status: int
var errors: PackedStringArray


func _init(
	p_status: Status,
	p_world_clock_seconds: float = 0.0,
	p_upstream_status: int = -1,
	p_errors: PackedStringArray = PackedStringArray()
) -> void:
	status = p_status
	world_clock_seconds = p_world_clock_seconds
	upstream_status = p_upstream_status
	errors = p_errors.duplicate()


func is_success() -> bool:
	return status == Status.SAVED or status == Status.LOADED_PRIMARY or status == Status.LOADED_BACKUP

func is_loaded() -> bool:
	return status == Status.LOADED_PRIMARY or status == Status.LOADED_BACKUP
