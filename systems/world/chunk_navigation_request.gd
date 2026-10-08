class_name ChunkNavigationRequest
extends RefCounted

enum Kind { SYNC_REGIONS, UPDATE_OBSTACLE }

var kind: Kind
var observed_revision: int
var target_revision: int
var admitted_keys: Array[StringName]
var unloaded_keys: Array[StringName]
var next_active_keys: Array[StringName]
var chunk_key: StringName
var obstacle_revision: int
var blocked: bool


func _init(
	p_kind: Kind,
	p_observed_revision: int,
	p_target_revision: int,
	p_admitted_keys: Array[StringName] = [],
	p_unloaded_keys: Array[StringName] = [],
	p_next_active_keys: Array[StringName] = [],
	p_chunk_key: StringName = &"",
	p_obstacle_revision: int = 0,
	p_blocked: bool = false
) -> void:
	kind = p_kind
	observed_revision = p_observed_revision
	target_revision = p_target_revision
	admitted_keys = p_admitted_keys.duplicate()
	unloaded_keys = p_unloaded_keys.duplicate()
	next_active_keys = p_next_active_keys.duplicate()
	chunk_key = p_chunk_key
	obstacle_revision = p_obstacle_revision
	blocked = p_blocked


static func from_delta(delta: ChunkAdmissionDelta) -> ChunkNavigationRequest:
	if delta == null:
		return null
	return ChunkNavigationRequest.new(
		Kind.SYNC_REGIONS,
		delta.from_revision,
		delta.to_revision,
		delta.admitted_keys,
		delta.unloaded_keys,
		delta.next_active_keys
	)


static func obstacle(
	p_chunk_key: StringName,
	p_observed_revision: int,
	p_obstacle_revision: int,
	p_blocked: bool
) -> ChunkNavigationRequest:
	return ChunkNavigationRequest.new(
		Kind.UPDATE_OBSTACLE,
		p_observed_revision,
		p_observed_revision,
		[], [], [],
		p_chunk_key,
		p_obstacle_revision,
		p_blocked
	)
