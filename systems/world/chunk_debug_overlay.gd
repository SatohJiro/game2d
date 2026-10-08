class_name ChunkDebugOverlay
extends CanvasLayer

var _label: Label

func _ready() -> void:
	layer = 90
	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	visible = false

func toggle() -> bool:
	visible = not visible
	return visible

func render_snapshot(snapshot: Dictionary) -> void:
	if _label == null: return
	_label.text = "CHUNK %s  rev:%d  active:%d" % [snapshot.get("center_key", ""), snapshot.get("revision", 0), snapshot.get("active_count", 0)]

func get_debug_text() -> String:
	return _label.text if _label != null else ""
