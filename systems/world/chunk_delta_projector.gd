class_name ChunkDeltaProjector
extends RefCounted

static func project(buildings: Array, resources: Array) -> Array[Dictionary]:
	var by_key: Dictionary = {}
	var seen: Dictionary = {}
	for value: Variant in buildings:
		var record := BuildingPlacementRecord.from_dto(value)
		if record == null or seen.has(record.instance_id): return []
		seen[record.instance_id] = true
		_append(by_key, record.transform.origin, ChunkDeltaEnvelope.KIND_BUILDING, record.instance_id, record.to_dto())
	for value: Variant in resources:
		if typeof(value) != TYPE_DICTIONARY: return []
		var position: Variant = ChunkDeltaEnvelope._position_from_dto(value.get("position"))
		var record := ResourceDepletionRecord.from_dto(value.get("payload"))
		if position == null or record == null or seen.has(record.instance_id): return []
		seen[record.instance_id] = true
		_append(by_key, position, ChunkDeltaEnvelope.KIND_RESOURCE, record.instance_id, record.to_dto())
	var output: Array[Dictionary] = []
	var keys := by_key.keys(); keys.sort()
	for key in keys:
		var envelope: ChunkDeltaEnvelope = by_key[key]
		envelope.entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["instance_id"]) < String(b["instance_id"]))
		output.append(envelope.to_dto())
	return output

static func _append(by_key: Dictionary, position: Vector2, kind_id: StringName, instance_id: StringName, payload: Dictionary) -> void:
	var coordinate := ChunkCoordinate.from_world_position(position)
	var key := ChunkCoordinate.to_key(coordinate)
	if not by_key.has(key): by_key[key] = ChunkDeltaEnvelope.new(coordinate, [])
	(by_key[key] as ChunkDeltaEnvelope).entries.append({"kind_id": String(kind_id), "instance_id": String(instance_id), "position": {"x": position.x, "y": position.y}, "payload": payload.duplicate(true)})

static func flatten(values: Variant) -> Dictionary:
	if typeof(values) != TYPE_ARRAY: return {}
	var buildings: Array[BuildingPlacementRecord] = []
	var resources: Array[ResourceDepletionRecord] = []
	var seen: Dictionary = {}
	for value: Variant in values:
		var envelope := ChunkDeltaEnvelope.from_dto(value)
		if envelope == null: return {}
		for entry in envelope.entries:
			var instance_id := StringName(entry["instance_id"])
			if seen.has(instance_id): return {}
			seen[instance_id] = true
			if StringName(entry["kind_id"]) == ChunkDeltaEnvelope.KIND_BUILDING: buildings.append(BuildingPlacementRecord.from_dto(entry["payload"]))
			else: resources.append(ResourceDepletionRecord.from_dto(entry["payload"]))
	return {"buildings": buildings, "resources": resources}
