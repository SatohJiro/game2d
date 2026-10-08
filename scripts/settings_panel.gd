class_name SettingsPanel
extends Control

## Settings UI (U3.4 presentation).
##
## Emits intents only; Main applies them through GameSettings and persists.
## Labels come from Localization; render() rebuilds on locale change.

signal volume_changed(value: float)
signal ui_scale_changed(value: float)
signal reduce_motion_toggled(enabled: bool)
signal locale_selected(locale: String)
signal remap_changed(action_id: StringName, keycode: int)

const LOCALES := ["vi", "en"]
const LOCALE_NAMES := ["Tiếng Việt", "English"]

var _is_open := false
var _armed_remap: StringName = &""
var _remap_buttons: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func is_open() -> bool:
	return _is_open


func toggle() -> bool:
	_is_open = not _is_open
	visible = _is_open
	_armed_remap = &""
	return _is_open


func render(settings: Dictionary) -> void:
	_armed_remap = &""
	_remap_buttons.clear()
	for child in get_children():
		child.queue_free()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PaloriaTheme.minimap_panel_stylebox())
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_WIDE)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = Localization.text("settings.title")
	title.add_theme_font_size_override("font_size", PaloriaTheme.FONT_TITLE)
	vbox.add_child(title)

	vbox.add_child(_slider_row(
		Localization.text("settings.volume"),
		0.0, 100.0, 1.0, float(settings.get("master_volume", 0.8)) * 100.0,
		func(value: float) -> void: volume_changed.emit(value / 100.0)))
	vbox.add_child(_slider_row(
		Localization.text("settings.ui_scale"),
		75.0, 150.0, 5.0, float(settings.get("ui_scale", 1.0)) * 100.0,
		func(value: float) -> void: ui_scale_changed.emit(value / 100.0)))

	var motion_row := HBoxContainer.new()
	motion_row.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_NORMAL)
	vbox.add_child(motion_row)
	var motion_check := CheckButton.new()
	motion_check.text = Localization.text("settings.reduce_motion")
	motion_check.set_pressed_no_signal(bool(settings.get("reduce_motion", false)))
	motion_check.toggled.connect(func(enabled: bool) -> void: reduce_motion_toggled.emit(enabled))
	motion_row.add_child(motion_check)

	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_NORMAL)
	vbox.add_child(lang_row)
	var lang_label := Label.new()
	lang_label.text = Localization.text("settings.language")
	lang_label.custom_minimum_size = Vector2(180, 0)
	lang_row.add_child(lang_label)
	var lang_option := OptionButton.new()
	for i in LOCALES.size():
		lang_option.add_item(LOCALE_NAMES[i], i)
	lang_option.selected = LOCALES.find(String(settings.get("locale", "vi")))
	lang_option.item_selected.connect(func(index: int) -> void: locale_selected.emit(LOCALES[index]))
	lang_row.add_child(lang_option)

	var remap_title := Label.new()
	remap_title.text = Localization.text("settings.remap_title")
	remap_title.add_theme_font_size_override("font_size", PaloriaTheme.FONT_NORMAL)
	vbox.add_child(remap_title)
	var remap: Dictionary = settings.get("input_remap", {})
	for action in settings.get("remap_actions", []):
		var action_id := StringName(action.get("id", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_NORMAL)
		vbox.add_child(row)
		var action_label := Label.new()
		action_label.text = Localization.text(action.get("label_key", ""))
		action_label.custom_minimum_size = Vector2(180, 0)
		row.add_child(action_label)
		var key_button := Button.new()
		key_button.custom_minimum_size = Vector2(140, 0)
		var keycode := int(remap.get(String(action_id), PlayerActionInputMapper.action_key(action_id)))
		key_button.text = OS.get_keycode_string(keycode)
		key_button.pressed.connect(func() -> void: _arm_remap(action_id))
		row.add_child(key_button)
		_remap_buttons[action_id] = key_button

	var hint := Label.new()
	hint.text = Localization.text("settings.hint")
	hint.add_theme_font_size_override("font_size", PaloriaTheme.FONT_TINY)
	vbox.add_child(hint)


func _slider_row(label_text: String, min_value: float, max_value: float, step: float, current: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_NORMAL)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = current
	slider.custom_minimum_size = Vector2(220, 0)
	slider.value_changed.connect(func(value: float) -> void: on_change.call(value))
	row.add_child(slider)
	var value_label := Label.new()
	value_label.text = "%d" % int(current)
	value_label.custom_minimum_size = Vector2(48, 0)
	slider.value_changed.connect(func(value: float) -> void: value_label.text = "%d" % int(value))
	row.add_child(value_label)
	return row


func _arm_remap(action_id: StringName) -> void:
	_armed_remap = action_id
	var button: Button = _remap_buttons.get(action_id)
	if button != null:
		button.text = Localization.text("settings.press_key")
		button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _armed_remap == &"" or not _is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var action_id := _armed_remap
		_armed_remap = &""
		var button: Button = _remap_buttons.get(action_id)
		if button != null:
			button.text = OS.get_keycode_string(event.keycode)
		remap_changed.emit(action_id, int(event.keycode))
		get_viewport().set_input_as_handled()
