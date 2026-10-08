class_name TownBuilder
extends Node2D
## TownBuilder (AT-A/AT-B): builds town structures under admitted chunk nodes.
## AT-B: real town art per kind; missing art falls back to a grey box.

const KIND_ART := {
	&"station": "res://assets/town/station_hall.png",
	&"landmark": "res://assets/town/clock_tower.png",
	&"platform": "res://assets/town/platform.png",
	&"stall": "res://assets/town/stall.png",
	&"bulletin": "res://assets/town/bulletin.png",
	&"house": "res://assets/town/house_a.png",
	&"vending": "res://assets/town/vending.png",
	&"torii": "res://assets/town/torii.png",
	&"shrine": "res://assets/town/shrine_hall.png",
	&"lantern": "res://assets/town/stone_lantern.png",
	&"lake": "res://assets/town/lake.png",
	&"bridge": "res://assets/town/bridge.png",
	&"dock": "res://assets/town/dock.png",
	&"gate": "res://assets/town/town_gate.png",
	&"sakura": "res://assets/town/sakura_tree.png",
	&"pole": "res://assets/town/power_pole.png",
}

## Alternate art for repeated kinds (cycled by structure index).
const KIND_ART_ALT := {
	&"house": ["res://assets/town/house_a.png", "res://assets/town/house_b.png"],
}

const FALLBACK_COLOR := Color(0.6, 0.6, 0.6, 0.3)


func build_for_chunk(chunk_node: Node, coordinate: Vector2i) -> int:
	var built := 0
	var kind_counts := {}
	var origin := ChunkCoordinate.world_origin(coordinate)
	for entry in TownLayout.for_chunk(coordinate):
		var s := entry as Dictionary
		var node_name := "TownStructure_%s" % String(s["id"])
		if chunk_node.get_node_or_null(node_name) != null:
			continue
		var holder := Node2D.new()
		holder.name = node_name
		var size := s["size"] as Vector2
		holder.position = (s["position"] as Vector2) - origin
		var kind := s["kind"] as StringName
		var art_path := _art_for_kind(kind, kind_counts)
		if art_path.is_empty():
			var box := ColorRect.new()
			box.size = size
			box.position = -size / 2.0
			box.color = FALLBACK_COLOR
			holder.add_child(box)
		else:
			var sprite := Sprite2D.new()
			sprite.texture = load(art_path) as Texture2D
			holder.add_child(sprite)
		chunk_node.add_child(holder)
		built += 1
	return built


func _art_for_kind(kind: StringName, kind_counts: Dictionary) -> String:
	if KIND_ART_ALT.has(kind):
		var alts := KIND_ART_ALT[kind] as Array
		var idx := int(kind_counts.get(kind, 0)) % alts.size()
		kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1
		return String(alts[idx])
	kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1
	return String(KIND_ART.get(kind, ""))


func structure_node(chunk_node: Node, structure_id: String) -> Node:
	return chunk_node.get_node_or_null("TownStructure_%s" % structure_id)


## Anchor interactables spawned per chunk (id -> dialogue key).
const ANCHOR_DIALOGUE := {
	&"town_station": "anchor.town_station.line",
	&"bulletin": "anchor.bulletin.line",
	&"shrine": "anchor.shrine.line",
	&"fishing_spot": "anchor.fishing_spot.line",
	&"sunset_vista": "anchor.sunset_vista.line",
}


func build_anchors_for_chunk(chunk_node: Node, coordinate: Vector2i) -> int:
	var built := 0
	var origin := ChunkCoordinate.world_origin(coordinate)
	for district in TownDistrictDB.for_chunk(coordinate):
		for anchor in (district as Dictionary)["anchors"]:
			var a := anchor as Dictionary
			var anchor_id := a["id"] as StringName
			if not ANCHOR_DIALOGUE.has(anchor_id):
				continue
			var node_name := "TownAnchor_%s" % String(anchor_id)
			if chunk_node.get_node_or_null(node_name) != null:
				continue
			var node := TownAnchor.new()
			node.name = node_name
			node.position = (a["position"] as Vector2) - origin
			chunk_node.add_child(node)
			node.setup(anchor_id, ANCHOR_DIALOGUE[anchor_id])
			built += 1
	return built


func build_npcs_for_chunk(chunk_node: Node, coordinate: Vector2i) -> int:
	var built := 0
	for entry in NpcDB.all():
		var npc := entry as Dictionary
		if ChunkCoordinate.from_world_position(npc["home"] as Vector2) != coordinate:
			continue
		var node_name := "TownNPC_%s" % String(npc["id"])
		if chunk_node.get_node_or_null(node_name) != null:
			continue
		var node := TownNPC.new()
		node.name = node_name
		node.add_to_group("town_npc")
		chunk_node.add_child(node)
		node.setup(npc["id"])
		built += 1
	_build_wires(chunk_node, coordinate)
	return built


## Catenary power lines between poles of the same chunk.
func _build_wires(chunk_node: Node, coordinate: Vector2i) -> void:
	var origin := ChunkCoordinate.world_origin(coordinate)
	var poles: Array[Vector2] = []
	for entry in TownLayout.for_chunk(coordinate):
		var s := entry as Dictionary
		if (s["kind"] as StringName) == &"pole":
			poles.append((s["position"] as Vector2) + Vector2(0, -38))
	poles.sort()
	for i in range(poles.size() - 1):
		var a := poles[i]
		var b := poles[i + 1]
		if a.distance_to(b) > 700.0:
			continue
		var line := Line2D.new()
		line.name = "PowerWire_%d" % i
		var points := PackedVector2Array()
		for t in 13:
			var p := a.lerp(b, t / 12.0)
			p.y += sin(PI * t / 12.0) * 18.0
			points.append(p - origin)
		line.points = points
		line.width = 1.5
		line.default_color = Color(0.15, 0.15, 0.2, 0.8)
		chunk_node.add_child(line)
