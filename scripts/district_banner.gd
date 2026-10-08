class_name DistrictBanner
extends CanvasLayer

## AT-G: location title card when the player enters a named district.
## Fades in, holds, fades out. Skipped when reduce_motion is on.

var _label: Label
var _timer := 0.0
var _phase := 0  # 0 idle, 1 in, 2 hold, 3 out

const FADE_IN := 0.6
const HOLD := 2.2
const FADE_OUT := 0.8


func _ready() -> void:
	layer = 60
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.position = Vector2(-300, 90)
	_label.size = Vector2(600, 48)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func show_district(name_key: String, reduce_motion: bool) -> void:
	if reduce_motion:
		return
	_label.text = "—  %s  —" % Localization.text(name_key)
	_timer = 0.0
	_phase = 1


func _process(delta: float) -> void:
	if _phase == 0:
		return
	_timer += delta
	match _phase:
		1:
			_label.modulate.a = minf(1.0, _timer / FADE_IN)
			if _timer >= FADE_IN:
				_phase = 2
				_timer = 0.0
		2:
			if _timer >= HOLD:
				_phase = 3
				_timer = 0.0
		3:
			_label.modulate.a = maxf(0.0, 1.0 - _timer / FADE_OUT)
			if _timer >= FADE_OUT:
				_phase = 0
