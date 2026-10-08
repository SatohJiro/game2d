class_name NpcDB
extends RefCounted

## AT-F: authored NPC data for Paloria Luminous Town.
## Each NPC has a home, per-phase hangout spots, and dialogue lines.
## Schedules follow the world phases (day/dusk/night/dawn).

const NPCS := [
	{
		"id": &"elder_hana", "name_key": "npc.elder_hana", "art": "res://assets/hero/npc_elder.png",
		"home": Vector2(2250, 300),
		"spots": {&"day": Vector2(1536, -620), &"dusk": Vector2(1600, 200), &"night": Vector2(2250, 300), &"dawn": Vector2(2250, 300)},
		"dialogue": "npc.elder_hana.line",
	},
	{
		"id": &"merchant_taro", "name_key": "npc.merchant_taro", "art": "res://assets/hero/npc_merchant.png",
		"home": Vector2(1500, 820),
		"spots": {&"day": Vector2(1400, 660), &"dusk": Vector2(1500, 820), &"night": Vector2(1500, 820), &"dawn": Vector2(1400, 660)},
		"dialogue": "npc.merchant_taro.line",
	},
	{
		"id": &"kid_sora", "name_key": "npc.kid_sora", "art": "res://assets/hero/npc_kid.png",
		"home": Vector2(2450, 440),
		"spots": {&"day": Vector2(1536, 1420), &"dusk": Vector2(2450, 440), &"night": Vector2(2450, 440), &"dawn": Vector2(1536, 1420)},
		"dialogue": "npc.kid_sora.line",
	},
	{
		"id": &"fisher_umi", "name_key": "npc.fisher_umi", "art": "res://assets/hero/npc_merchant.png",
		"home": Vector2(1450, 1380),
		"spots": {&"day": Vector2(1450, 1400), &"dusk": Vector2(1450, 1400), &"night": Vector2(1450, 1380), &"dawn": Vector2(1450, 1400)},
		"dialogue": "npc.fisher_umi.line",
	},
]


static func all() -> Array:
	return NPCS


static func find(id: StringName) -> Dictionary:
	for npc in NPCS:
		if (npc as Dictionary)["id"] == id:
			return npc
	return {}


static func spot_for(npc: Dictionary, phase: StringName) -> Vector2:
	var spots := npc["spots"] as Dictionary
	return spots.get(phase, npc["home"]) as Vector2
