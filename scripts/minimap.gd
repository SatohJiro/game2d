class_name MinimapPanel
extends Control

## Fast-travel minimap + destination picker (U2.6d presentation).
##
## Read-only: renders the discovery view snapshot and emits a travel intent.
## All domain mutation goes through Main.try_fast_travel(); this panel never
## touches inventory, player, discovery state or chunk admission directly.
## Accessibility: keyboard/gamepad navigation via ItemList, no flashing or
## motion, tile states distinguished by symbols/borders/labels, not color
## alone, and a text legend plus result messages.

signal travel_requested(destination_id: StringName)

var _map_view: MinimapView
var _destination_list: ItemList
var _cost_label: Label
var _status_label: Label
var _travel_button: Button
var _snapshot: Dictionary = {}
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
	if _is_open and is_inside_tree():
		_destination_list.grab_focus()
	return _is_open


func render_snapshot(snapshot: Dictionary) -> void:
	_snapshot = (snapshot as Dictionary).duplicate(true)
	var tiles: Array[Dictionary] = []
	for raw_tile in _snapshot.get("tiles", []):
		if raw_tile is Dictionary:
			tiles.append(raw_tile)
	_map_view.set_tiles(tiles)
	_rebuild_destination_list(tiles)


func get_snapshot() -> Dictionary:
	return (_snapshot as Dictionary).duplicate(true)


func get_listed_destination_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for i in _destination_list.item_count:
		ids.append(StringName(String(_destination_list.get_item_metadata(i))))
	return ids


func select_destination(destination_id: StringName) -> bool:
	for i in _destination_list.item_count:
		if StringName(String(_destination_list.get_item_metadata(i))) == destination_id:
			_destination_list.select(i)
			_destination_list.ensure_current_is_visible()
			return true
	return false


func get_selected_destination_id() -> StringName:
	var selected := _destination_list.get_selected_items()
	if selected.is_empty():
		return &""
	return StringName(String(_destination_list.get_item_metadata(selected[0])))


func confirm_selection() -> void:
	var destination_id := get_selected_destination_id()
	if destination_id == &"":
		_status_label.text = "Hãy chọn một điểm đến trong danh sách."
		return
	travel_requested.emit(destination_id)


func show_travel_result(result: FastTravelResult) -> void:
	if result == null:
		_status_label.text = "Yêu cầu không hợp lệ."
		return
	_status_label.text = _result_message(result)


func _rebuild_destination_list(tiles: Array[Dictionary]) -> void:
	_destination_list.clear()
	var rows: Array[Dictionary] = []
	for tile in tiles:
		if not bool(tile.get("discovered", false)):
			continue
		var key := String(tile.get("chunk_key", ""))
		var destination_id := FastTravelDestinationCatalog.destination_id_for_chunk(StringName(key))
		if destination_id == &"":
			continue
		rows.append({"id": destination_id, "key": key, "tile": tile})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["key"]) < String(b["key"]))
	for row in rows:
		var tile: Dictionary = row["tile"]
		var coord: Array = tile.get("coordinate", [0, 0])
		var label := "Chunk (%d, %d)" % [int(coord[0]), int(coord[1])]
		if bool(tile.get("current", false)):
			label += " (hiện tại)"
		var index := _destination_list.add_item(label)
		_destination_list.set_item_metadata(index, String(row["id"]))


static func _result_message(result: FastTravelResult) -> String:
	match result.status:
		FastTravelResult.Status.OK:
			var coord: Array = [0, 0]
			var parsed: Array[Vector2i] = []
			if ChunkCoordinate.try_parse_key(result.chunk_key, parsed):
				coord = [parsed[0].x, parsed[0].y]
			return "Đã dịch chuyển tới Chunk (%d, %d)!" % [int(coord[0]), int(coord[1])]
		FastTravelResult.Status.SAME_DESTINATION:
			return "Bạn đang ở đây rồi."
		FastTravelResult.Status.UNDISCOVERED:
			return "Chưa khám phá vùng này."
		FastTravelResult.Status.UNKNOWN_DESTINATION:
			return "Điểm đến không hợp lệ."
		FastTravelResult.Status.STALE_DISCOVERY:
			return "Dữ liệu bản đồ đã cũ, hãy mở lại bảng."
		FastTravelResult.Status.ENCOUNTER_GUARD:
			return "Không thể dịch chuyển khi đang giao chiến!"
		FastTravelResult.Status.COOLDOWN_ACTIVE:
			return "Đang hồi chiêu dịch chuyển."
		FastTravelResult.Status.INSUFFICIENT_COST:
			return "Cần 1 Cầu Thu Phục để dịch chuyển."
		FastTravelResult.Status.COMMIT_FAILED:
			return "Dịch chuyển thất bại, đã hoàn lại chi phí."
		_:
			return "Yêu cầu không hợp lệ."


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
	title.text = "BẢN ĐỒ & DỊCH CHUYỂN NHANH"
	title.add_theme_font_size_override("font_size", PaloriaTheme.FONT_TITLE)
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	_map_view = MinimapView.new()
	hbox.add_child(_map_view)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", PaloriaTheme.SEPARATION_NORMAL)
	hbox.add_child(right)
	var list_label := Label.new()
	list_label.text = "Điểm đến đã khám phá:"
	right.add_child(list_label)
	_destination_list = ItemList.new()
	_destination_list.custom_minimum_size = Vector2(250, 190)
	_destination_list.allow_reselect = true
	right.add_child(_destination_list)
	_cost_label = Label.new()
	_cost_label.text = "Chi phí: 1 Cầu Thu Phục / lần (hồi 30s)"
	right.add_child(_cost_label)
	_travel_button = Button.new()
	_travel_button.text = "Dịch chuyển (Enter)"
	_travel_button.pressed.connect(confirm_selection)
	right.add_child(_travel_button)

	var legend := Label.new()
	legend.text = "■ đã khám phá (vạch góc)  |  ▨ trong sương mù  |  ● vị trí hiện tại (viền vàng)"
	legend.add_theme_font_size_override("font_size", PaloriaTheme.FONT_TINY)
	vbox.add_child(legend)

	_status_label = Label.new()
	_status_label.text = "Chọn điểm đến rồi nhấn Dịch chuyển."
	vbox.add_child(_status_label)

	var hint := Label.new()
	hint.text = "M: đóng/mở  •  ↑↓: chọn  •  Enter: dịch chuyển"
	hint.add_theme_font_size_override("font_size", PaloriaTheme.FONT_TINY)
	vbox.add_child(hint)

	_destination_list.item_activated.connect(_on_item_activated)


func _on_item_activated(_index: int) -> void:
	confirm_selection()
