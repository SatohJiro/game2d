class_name MusicContext
extends RefCounted

## AT-E: music/ambience context domain.
## Gameplay builds a snapshot {zone, phase, weather, danger}; this resolves
## stable cue IDs and ambience mixes. No file paths leave the audio layer.

const CUE_DAY := &"music.town.day"
const CUE_DUSK := &"music.town.dusk"
const CUE_NIGHT := &"music.town.night"
const CUE_RAIN := &"music.town.rain"
const CUE_SHRINE := &"music.shrine.story"
const CUE_DANGER := &"music.outskirts.danger"

const BED_WIND := &"amb.wind"
const BED_BIRDS := &"amb.birds"
const BED_CICADAS := &"amb.cicadas"
const BED_CRICKETS := &"amb.crickets"
const BED_RAIN := &"amb.rain"
const BED_WATER := &"amb.water"
const BED_TRAIN := &"amb.train"


static func snapshot(zone: StringName, phase: StringName, weather: int, danger: bool) -> Dictionary:
	return {"zone": zone, "phase": phase, "weather": weather, "danger": danger}


static func cue_for(ctx: Dictionary) -> StringName:
	if bool(ctx.get("danger", false)):
		return CUE_DANGER
	if StringName(ctx.get("zone", &"")) == &"shrine_hill":
		return CUE_SHRINE
	if int(ctx.get("weather", 0)) == WeatherDirector.Weather.RAIN:
		return CUE_RAIN
	match StringName(ctx.get("phase", &"day")):
		&"dusk":
			return CUE_DUSK
		&"night":
			return CUE_NIGHT
	return CUE_DAY


## Ambience bed -> target gain (0.0 = silent).
static func ambience_mix(ctx: Dictionary) -> Dictionary:
	var phase := StringName(ctx.get("phase", &"day"))
	var weather := int(ctx.get("weather", 0))
	var zone := StringName(ctx.get("zone", &""))
	var raining := weather == WeatherDirector.Weather.RAIN
	var mix := {
		BED_WIND: 0.30,
		BED_BIRDS: 0.0, BED_CICADAS: 0.0, BED_CRICKETS: 0.0,
		BED_RAIN: 0.0, BED_WATER: 0.0, BED_TRAIN: 0.0,
	}
	if raining:
		mix[BED_RAIN] = 0.70
	elif phase == &"day":
		mix[BED_BIRDS] = 0.55
	elif phase == &"dusk":
		mix[BED_CICADAS] = 0.55
	elif phase == &"night":
		mix[BED_CRICKETS] = 0.50
	if zone == &"lakeside":
		mix[BED_WATER] = 0.60
	if zone == &"station_plaza":
		mix[BED_TRAIN] = 0.35
	return mix
