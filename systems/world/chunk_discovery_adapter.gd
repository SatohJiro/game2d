class_name ChunkDiscoveryAdapter
extends RefCounted

var state := ChunkDiscoveryState.new()


func observe_center(center: Vector2i, observed_revision: int = -1) -> ChunkDiscoveryResult:
	var request_revision := state.revision if observed_revision < 0 else observed_revision
	return state.discover(ChunkDiscoveryRequest.new(ChunkCoordinate.to_key(center), request_revision))


func create_view_snapshot(center: Vector2i, active_keys: Array[StringName]) -> Dictionary:
	return state.create_view_snapshot(center, active_keys).duplicate(true)


func export_dto() -> Dictionary:
	return state.to_dto().duplicate(true)


func create_persistence_state() -> ChunkDiscoveryState:
	return ChunkDiscoveryState.from_dto(state.to_dto())


func import_dto(value: Variant) -> bool:
	var parsed := ChunkDiscoveryState.from_dto(value)
	if parsed == null: return false
	state = parsed
	return true
