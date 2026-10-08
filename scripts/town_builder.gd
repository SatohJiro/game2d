class_name TownBuilder
extends Node2D
## TownBuilder (AT-A): builds town structures under admitted chunk nodes.
## Greybox phase: translucent footprint boxes + labels. AT-B replaces the
## visuals with real art via TownArt (same node names, same footprints).

const KIND_COLORS := {
	&"station": Color(0.3, 0.5, 0.9, 0.35),
	&"landmark": Color(0.9, 0.75, 0.2, 0.35),
	&"platform": Color(0.5, 0.5, 0.55, 0.35),
	&"stall": Color(0.9, 0.5, 0.25, 0.35),
	&"bulletin": Color(0.7, 0.6, 0.3, 0.35),
	&"house": Color(0.35, 0.65, 0.9, 0.35),
	&"vending": Color(0.9, 0.3, 0.3, 0.35),
	&"torii": Color(0.85, 0.25, 0.2, 0.35),
	&"shrine": Color(0.75, 0.2, 0.2, 0.35),
	&"lantern": Color(1.0, 0.7, 0.3, 0.35),
	&"lake": Color(0.25, 0.55, 0.9, 0.35),
	&"bridge": Color(0.6, 0.45, 0.3, 0.35),
	&"dock": Color(0.6, 0.45, 0.3, 0.35),
	&"gate": Color(0.5, 0.35, 0.7, 0.35),
}

const FALLBACK_COLOR := Color(0.6, 0.6, 0.6, 0.3)


func build_for_chunk(chunk_node: Node, coordinate: Vector2i) -> int:
	var built := 0
	for entry in TownLayout.for_chunk(coordinate):
		var s := entry as Dictionary
		var node_name := "TownStructure_%s" % String(s["id"])
		if chunk_node.get_node_or_null(node_name) != null:
			continue
		var holder := Node2D.new()
		holder.name = node_name
		var size := s["size"] as Vector2
		var pos := s["position"] as Vector2
		holder.position = pos
		var box := ColorRect.new()
		box.size = size
		box.position = -size / 2.0
		box.color = KIND_COLORS.get(s["kind"], FALLBACK_COLOR)
		holder.add_child(box)
		var label := Label.new()
		label.text = String(s["id"])
		label.position = -size / 2.0 + Vector2(4, 4)
		label.add_theme_font_size_override("font_size", 12)
		holder.add_child(label)
		chunk_node.add_child(holder)
		built += 1
	return built


func structure_node(chunk_node: Node, structure_id: String) -> Node:
	return chunk_node.get_node_or_null("TownStructure_%s" % structure_id)
