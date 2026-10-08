class_name WorldClock
extends RefCounted

## AT-C: typed time-of-day domain for Paloria Luminous Town.
## Wraps the existing day_time/day_duration convention (180s cycle):
##   DAY   progress < 0.45
##   DUSK  0.45 <= progress < 0.65
##   NIGHT 0.65 <= progress < 0.88
##   DAWN  progress >= 0.88

enum Phase { DAY, DUSK, NIGHT, DAWN }

const DAY_DURATION := 180.0


static func progress_for_seconds(seconds: float) -> float:
	return fmod(seconds / DAY_DURATION, 1.0)


static func phase_for_progress(p: float) -> int:
	if p < 0.45:
		return Phase.DAY
	if p < 0.65:
		return Phase.DUSK
	if p < 0.88:
		return Phase.NIGHT
	return Phase.DAWN


static func phase_name(phase: int) -> StringName:
	match phase:
		Phase.DAY:
			return &"day"
		Phase.DUSK:
			return &"dusk"
		Phase.NIGHT:
			return &"night"
	return &"dawn"


## Lamps/windows glow from late dusk through dawn.
static func is_dark(progress: float) -> bool:
	return progress >= 0.58 or progress < 0.06


## Ambient light color across the full cycle (dawn pink -> day -> dusk -> night).
static func ambient_color(progress: float) -> Color:
	var c := Color.WHITE
	if progress < 0.40:
		c = Color(1.0, 0.98, 0.94)
	elif progress < 0.45:
		var t := (progress - 0.40) / 0.05
		c = Color(1.0, 0.98, 0.94).lerp(Color(1.0, 0.95, 0.88), t)
	elif progress < 0.58:
		var t2 := (progress - 0.45) / 0.13
		c = Color(1.0, 0.95, 0.88).lerp(Color(1.0, 0.72, 0.50), t2)
	elif progress < 0.65:
		var t3 := (progress - 0.58) / 0.07
		c = Color(1.0, 0.72, 0.50).lerp(Color(0.55, 0.45, 0.70), t3)
	elif progress < 0.88:
		var t4 := (progress - 0.65) / 0.23
		c = Color(0.55, 0.45, 0.70).lerp(Color(0.42, 0.48, 0.75), t4)
	elif progress < 0.96:
		var t5 := (progress - 0.88) / 0.08
		c = Color(0.42, 0.48, 0.75).lerp(Color(1.0, 0.80, 0.72), t5)
	else:
		var t6 := (progress - 0.96) / 0.04
		c = Color(1.0, 0.80, 0.72).lerp(Color(1.0, 0.98, 0.94), t6)
	return c
