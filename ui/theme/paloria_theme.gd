class_name PaloriaTheme
extends RefCounted

## Design tokens (U3.1): single source of truth for UI colors, type scale,
## radii and spacing. Code-built UI must use these constants and factories
## instead of inline StyleBoxFlat values. Inline sub-resources inside
## hud.tscn predate the token system and migrate when their panels are
## rebuilt in later U3 packages (layout unchanged by this package).

# Palette
const PANEL_BG := Color(0.07, 0.09, 0.14, 0.88)
const PANEL_BORDER := Color(0.25, 0.45, 0.7, 0.8)
const CARD_BG := Color(0.1, 0.14, 0.22, 0.95)
const CARD_BORDER := Color(0.2, 0.5, 0.8, 0.6)
const COOKING_CARD_BG := Color(0.12, 0.15, 0.22, 0.95)
const COOKING_CARD_BORDER := Color(1.0, 0.65, 0.2, 0.8)
const MINIMAP_BG := Color(0.06, 0.08, 0.12, 0.96)
const MINIMAP_BORDER := Color(0.30, 0.50, 0.75, 0.9)
const ACCENT_GOLD := Color(1.0, 0.9, 0.4)
const TEXT_PRIMARY := Color(1.0, 1.0, 1.0)
const TEXT_MUTED := Color(0.7, 0.8, 0.9)
const TEXT_WARM := Color(1.0, 0.85, 0.4)
const TEXT_FRESH := Color(0.8, 0.85, 0.9)
const AFFORDABLE := Color(0.5, 0.9, 1.0)
const UNAFFORDABLE := Color(1.0, 0.5, 0.5)
const SUCCESS_GREEN := Color(0.4, 1.0, 0.5)

# Bars
const HP_FILL := Color(0.2, 0.85, 0.4)
const SP_FILL := Color(0.2, 0.7, 1.0)
const HUNGER_FILL := Color(1.0, 0.6, 0.2)
const THIRST_FILL := Color(0.18, 0.78, 1.0)
const BAR_BG := Color(0.12, 0.14, 0.18, 0.9)

# Type scale
const FONT_TITLE := 20
const FONT_NORMAL := 12
const FONT_SMALL := 9
const FONT_TINY := 13

# Shape and spacing
const RADIUS_PANEL := 8
const RADIUS_CARD := 6
const RADIUS_MINIMAP := 10
const BORDER_THIN := 1
const BORDER_THICK := 2
const MARGIN_TIGHT := 6
const MARGIN_NORMAL := 8
const MARGIN_WIDE := 10
const MARGIN_LARGE := 16
const SEPARATION_TIGHT := 2
const SEPARATION_NORMAL := 8
const SEPARATION_WIDE := 10
const SEPARATION_XWIDE := 12


static func panel_stylebox() -> StyleBoxFlat:
	return _flat(PANEL_BG, PANEL_BORDER, RADIUS_PANEL, BORDER_THIN)


static func card_stylebox() -> StyleBoxFlat:
	return _flat(CARD_BG, CARD_BORDER, RADIUS_CARD, BORDER_THIN)


static func cooking_card_stylebox() -> StyleBoxFlat:
	return _flat(COOKING_CARD_BG, COOKING_CARD_BORDER, RADIUS_PANEL, BORDER_THIN)


static func minimap_panel_stylebox() -> StyleBoxFlat:
	return _flat(MINIMAP_BG, MINIMAP_BORDER, RADIUS_MINIMAP, BORDER_THICK)


static func _flat(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = bg
	stylebox.border_color = border
	stylebox.set_border_width_all(border_width)
	stylebox.set_corner_radius_all(radius)
	return stylebox
