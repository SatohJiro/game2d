class_name TownDistrictDB
extends RefCounted

## AT-A: authored district data for Paloria Luminous Town.
## Town occupies chunks (0..2, -1..1); chunk size is 1024 (see ChunkCoordinate).
## Base camp at world origin sits inside the farm_edge district.

const DISTRICTS := [
	{
		"id": &"farm_edge", "name_key": "district.farm_edge",
		"chunk": Vector2i(0, 0), "rect": Rect2(0, 0, 1024, 1024),
		"anchors": [
			{"id": &"farm_plots", "kind": &"farm", "position": Vector2(60, 60)},
			{"id": &"ranch", "kind": &"ranch", "position": Vector2(-80, 40)},
		],
	},
	{
		"id": &"station_plaza", "name_key": "district.station_plaza",
		"chunk": Vector2i(1, 0), "rect": Rect2(1024, 0, 1024, 512),
		"anchors": [
			{"id": &"town_station", "kind": &"fast_travel", "position": Vector2(1400, 220)},
			{"id": &"clock_tower", "kind": &"landmark", "position": Vector2(1620, 140)},
		],
	},
	{
		"id": &"market_street", "name_key": "district.market_street",
		"chunk": Vector2i(1, 0), "rect": Rect2(1024, 512, 1024, 512),
		"anchors": [
			{"id": &"stall_north", "kind": &"shop", "position": Vector2(1300, 700)},
			{"id": &"stall_south", "kind": &"shop", "position": Vector2(1500, 760)},
			{"id": &"bulletin", "kind": &"quest", "position": Vector2(1700, 700)},
		],
	},
	{
		"id": &"hillside", "name_key": "district.hillside",
		"chunk": Vector2i(2, 0), "rect": Rect2(2048, 0, 1024, 1024),
		"anchors": [
			{"id": &"house_row", "kind": &"housing", "position": Vector2(2300, 300)},
			{"id": &"vending", "kind": &"shop", "position": Vector2(2500, 600)},
			{"id": &"shortcut", "kind": &"shortcut", "position": Vector2(2700, 800)},
		],
	},
	{
		"id": &"shrine_hill", "name_key": "district.shrine_hill",
		"chunk": Vector2i(1, -1), "rect": Rect2(1024, -1024, 1024, 1024),
		"anchors": [
			{"id": &"shrine", "kind": &"shrine", "position": Vector2(1536, -700)},
			{"id": &"sunset_vista", "kind": &"vista", "position": Vector2(1536, -850)},
			{"id": &"rare_spawn", "kind": &"capture", "position": Vector2(1400, -600)},
		],
	},
	{
		"id": &"lakeside", "name_key": "district.lakeside",
		"chunk": Vector2i(1, 1), "rect": Rect2(1024, 1024, 1024, 1024),
		"anchors": [
			{"id": &"lake", "kind": &"water", "position": Vector2(1536, 1500)},
			{"id": &"fishing_spot", "kind": &"fishing", "position": Vector2(1450, 1420)},
			{"id": &"foot_bridge", "kind": &"bridge", "position": Vector2(1600, 1500)},
		],
	},
	{
		"id": &"outskirts_west", "name_key": "district.outskirts",
		"chunk": Vector2i(0, -1), "rect": Rect2(0, -1024, 1024, 1024), "anchors": [],
	},
	{
		"id": &"outskirts_east", "name_key": "district.outskirts",
		"chunk": Vector2i(2, -1), "rect": Rect2(2048, -1024, 1024, 1024), "anchors": [],
	},
	{
		"id": &"outskirts_sw", "name_key": "district.outskirts",
		"chunk": Vector2i(0, 1), "rect": Rect2(0, 1024, 1024, 1024), "anchors": [],
	},
	{
		"id": &"outskirts_se", "name_key": "district.outskirts",
		"chunk": Vector2i(2, 1), "rect": Rect2(2048, 1024, 1024, 1024), "anchors": [],
	},
]


static func all() -> Array:
	return DISTRICTS


static func for_chunk(coordinate: Vector2i) -> Array:
	var result := []
	for district in DISTRICTS:
		if (district as Dictionary)["chunk"] == coordinate:
			result.append(district)
	return result


static func find(id: StringName) -> Dictionary:
	for district in DISTRICTS:
		if (district as Dictionary)["id"] == id:
			return district
	return {}


static func anchor_by_id(anchor_id: StringName) -> Dictionary:
	for district in DISTRICTS:
		for anchor in (district as Dictionary)["anchors"]:
			if (anchor as Dictionary)["id"] == anchor_id:
				return anchor
	return {}
