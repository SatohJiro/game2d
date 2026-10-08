class_name TownLayout
extends RefCounted

## AT-A: authored greybox structure placements for the town.
## Each entry: id, district, kind, position (world), size (greybox footprint).
## Kinds map to art in AT-B; the greybox only needs footprint + label.

const STRUCTURES := [
	# station_plaza
	{"id": "station_hall", "district": &"station_plaza", "kind": &"station", "position": Vector2(1400, 220), "size": Vector2(220, 120)},
	{"id": "clock_tower", "district": &"station_plaza", "kind": &"landmark", "position": Vector2(1620, 140), "size": Vector2(64, 160)},
	{"id": "platform", "district": &"station_plaza", "kind": &"platform", "position": Vector2(1400, 340), "size": Vector2(320, 40)},
	# market_street
	{"id": "stall_1", "district": &"market_street", "kind": &"stall", "position": Vector2(1300, 700), "size": Vector2(96, 64)},
	{"id": "stall_2", "district": &"market_street", "kind": &"stall", "position": Vector2(1500, 760), "size": Vector2(96, 64)},
	{"id": "bulletin", "district": &"market_street", "kind": &"bulletin", "position": Vector2(1700, 700), "size": Vector2(48, 64)},
	# hillside
	{"id": "house_a", "district": &"hillside", "kind": &"house", "position": Vector2(2250, 280), "size": Vector2(128, 112)},
	{"id": "house_b", "district": &"hillside", "kind": &"house", "position": Vector2(2450, 420), "size": Vector2(128, 112)},
	{"id": "house_c", "district": &"hillside", "kind": &"house", "position": Vector2(2300, 620), "size": Vector2(128, 112)},
	{"id": "vending", "district": &"hillside", "kind": &"vending", "position": Vector2(2500, 600), "size": Vector2(40, 64)},
	# shrine_hill
	{"id": "torii_1", "district": &"shrine_hill", "kind": &"torii", "position": Vector2(1536, -350), "size": Vector2(96, 96)},
	{"id": "torii_2", "district": &"shrine_hill", "kind": &"torii", "position": Vector2(1536, -550), "size": Vector2(96, 96)},
	{"id": "shrine_hall", "district": &"shrine_hill", "kind": &"shrine", "position": Vector2(1536, -700), "size": Vector2(192, 128)},
	{"id": "lantern_row", "district": &"shrine_hill", "kind": &"lantern", "position": Vector2(1450, -450), "size": Vector2(24, 48)},
	# lakeside
	{"id": "lake", "district": &"lakeside", "kind": &"lake", "position": Vector2(1536, 1500), "size": Vector2(420, 260)},
	{"id": "foot_bridge", "district": &"lakeside", "kind": &"bridge", "position": Vector2(1600, 1500), "size": Vector2(160, 48)},
	{"id": "dock", "district": &"lakeside", "kind": &"dock", "position": Vector2(1450, 1400), "size": Vector2(96, 32)},
	# farm_edge (gate marker; base camp structures already exist in main.tscn)
	{"id": "town_gate_w", "district": &"farm_edge", "kind": &"gate", "position": Vector2(900, 200), "size": Vector2(48, 96)},
]


static func all() -> Array:
	return STRUCTURES


static func for_chunk(coordinate: Vector2i) -> Array:
	var result := []
	for structure in STRUCTURES:
		var s := structure as Dictionary
		var district := TownDistrictDB.find(s["district"])
		if not district.is_empty() and (district as Dictionary)["chunk"] == coordinate:
			result.append(s)
	return result
