class_name ChunkSceneAdapter
extends RefCounted

const PLACEHOLDER_SCENE := preload("res://scenes/world/chunk_placeholder.tscn")

var container: Node2D
var applied_revision: int = 0
var _nodes: Dictionary = {}

func _init(p_container: Node2D) -> void:
	container = p_container

func apply_delta(delta: ChunkAdmissionDelta) -> bool:
	if not is_instance_valid(container) or delta == null or not delta.is_changed() or delta.from_revision != applied_revision:
		return false
	for key in delta.admitted_keys:
		if _nodes.has(key): return false
	for key in delta.unloaded_keys:
		if not _nodes.has(key): return false
	var staged: Array[ChunkPlaceholder] = []
	for key in delta.admitted_keys:
		var parsed: Array[Vector2i] = []
		var node := PLACEHOLDER_SCENE.instantiate() as ChunkPlaceholder
		if node == null or not ChunkCoordinate.try_parse_key(key, parsed) or not node.configure(key, parsed[0], delta.to_revision):
			for staged_node in staged: staged_node.free()
			if node != null: node.free()
			return false
		staged.append(node)
	for node in staged:
		container.add_child(node)
		_nodes[node.chunk_key] = node
	for key in delta.unloaded_keys:
		var old_node := _nodes[key] as ChunkPlaceholder
		_nodes.erase(key)
		old_node.queue_free()
	applied_revision = delta.to_revision
	return get_active_keys() == delta.next_active_keys

func get_active_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key in _nodes.keys(): keys.append(key as StringName)
	keys.sort()
	return keys

func get_node_for_key(key: StringName) -> ChunkPlaceholder:
	return _nodes.get(key) as ChunkPlaceholder

func cleanup() -> void:
	for node: ChunkPlaceholder in _nodes.values():
		if is_instance_valid(node): node.queue_free()
	_nodes.clear()
