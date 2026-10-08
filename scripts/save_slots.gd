class_name SaveSlotPanel
extends Control

## Save/load slot UI (U3.3 presentation).
##
## Lists save slots with metadata and emits intents; Main (coordinator)
## executes save/load/delete through SaveSlotManager and re-renders.
## Delete requires a two-press confirm. Autosave is a control only —
## Main owns the autosave timer and safety policy.

signal load_requested(slot_id: StringName)
signal save_requested(slot_id: StringName)
signal delete_requested(slot_id: StringName)
signal autosave_toggled(enabled: bool)

var _slots_box: VBoxContainer
var _autosave_check: CheckButton
var _armed_delete: StringName = &""
var _is_open := false


func _ready() -> void:
	_build_ui()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func is_open() -> bool:
	return _is_open


func toggle() -> bool:
	_is_open = not _is_open
	visible = _is_open
	return _is_open


func render_slots(slots: Array[Dictionary], autosave_enabled: bool, current_slot: StringName) -> void:
	_armed_delete = &""
	for child in _slots_box.get_children():
		child.queue_free()
	for slot in slots:
		_slots_box.add_child(_build_row(slot, current_slot))
	_autosave_check.set_pressed_no_signal(autosave_enabled)


func _build_row(slot: Dictionary, current_slot: StringName) -> Control:
	var slot_id := StringName(slot.get("slot_id", ""))
	var exists := bool(slot.get("exists", false))
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", PaloriaTheme.card_stylebox())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", PaloriaTheme.MARGIN_NORMAL)
	margin.add_theme_constant_override("margin_right", PaloriaTheme.MARGIN_NORMAL)
	margin.add_theme_constant_override("margin_top", PaloriaTheme.MARGIN_TIGHT)
	margin.add_theme_constant_override("margin_bottom", PaloriaTheme.MARGIN_TIGHT)
	row.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_NORMAL)
	margin.add_child(hbox)
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = _slot_info_text(slot, current_slot)
	info.add_theme_font_size_override("font_size", PaloriaTheme.FONT_NORMAL)
	hbox.add_child(info)
	if exists:
		var load_button := Button.new()
		load_button.text = Localization.text("slots.load")
		load_button.pressed.connect(func() -> void: load_requested.emit(slot_id))
		hbox.add_child(load_button)
	var save_button := Button.new()
	save_button.text = Localization.text("slots.save") if exists else Localization.text("slots.save_new")
	save_button.pressed.connect(func() -> void: save_requested.emit(slot_id))
	hbox.add_child(save_button)
	if exists:
		var delete_button := Button.new()
		delete_button.text = Localization.text("slots.delete")
		delete_button.pressed.connect(func() -> void: _on_delete_pressed(slot_id, delete_button))
		hbox.add_child(delete_button)
	return row


func _slot_info_text(slot: Dictionary, current_slot: StringName) -> String:
	var slot_id := String(slot.get("slot_id", ""))
	var label := Localization.text("slots.slot_label", {"n": slot_id.trim_prefix("slot_")})
	if slot_id == "autosave":
		label = Localization.text("slots.autosave_label")
	if not bool(slot.get("exists", false)):
		return Localization.text("slots.empty", {"label": label})
	var text := Localization.text("slots.info", {
		"label": label,
		"player": int(slot.get("player_level", 1)),
		"base": int(slot.get("base_level", 1)),
		"minutes": int(float(slot.get("clock_seconds", 0.0)) / 60.0),
	})
	if StringName(slot_id) == current_slot:
		text += Localization.text("slots.current")
	return text


func _on_delete_pressed(slot_id: StringName, button: Button) -> void:
	if _armed_delete == slot_id:
		_armed_delete = &""
		delete_requested.emit(slot_id)
	else:
		_armed_delete = slot_id
		button.text = Localization.text("slots.confirm_delete")


func _build_ui() -> void:
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
	title.text = Localization.text("slots.title")
	title.add_theme_font_size_override("font_size", PaloriaTheme.FONT_TITLE)
	vbox.add_child(title)

	_slots_box = VBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_TIGHT)
	_slots_box.custom_minimum_size = Vector2(420, 0)
	vbox.add_child(_slots_box)

	var autosave_row := HBoxContainer.new()
	autosave_row.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_NORMAL)
	vbox.add_child(autosave_row)
	_autosave_check = CheckButton.new()
	_autosave_check.text = Localization.text("slots.autosave_check")
	_autosave_check.toggled.connect(func(enabled: bool) -> void: autosave_toggled.emit(enabled))
	autosave_row.add_child(_autosave_check)

	var hint := Label.new()
	hint.text = Localization.text("slots.hint")
	hint.add_theme_font_size_override("font_size", PaloriaTheme.FONT_TINY)
	vbox.add_child(hint)
