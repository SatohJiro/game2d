class_name ContextPrompt
extends Label

## Contextual interaction hint (U3.4 presentation).
##
## A small floating label Main positions near the current interaction target.
## Text comes from Localization ("prompt.interact_hint"); this view only
## shows/hides/positions and never queries gameplay.


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", PaloriaTheme.FONT_NORMAL)
	add_theme_color_override("font_color", PaloriaTheme.TEXT_WARM)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", 6)
	z_index = 50


func show_prompt(text: String, screen_position: Vector2) -> void:
	self.text = text
	visible = true
	var viewport_size := get_viewport_rect().size
	var offset := Vector2(-size.x * 0.5, -size.y - 8.0)
	position = (screen_position + offset).clamp(Vector2.ZERO, viewport_size - size)


func hide_prompt() -> void:
	visible = false
