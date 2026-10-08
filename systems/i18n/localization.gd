class_name Localization
extends RefCounted

## Hand-rolled localization (U3.4).
##
## Static lookup over per-locale CSV tables in res://assets/i18n/<locale>.csv
## (columns: key,text). Missing keys fall back to the default locale, then to
## the key itself so untranslated strings stay visible and debuggable.
## Inventory/save storage keeps stable IDs; only display text goes through keys.

const DEFAULT_LOCALE := "vi"
const FALLBACK_LOCALE := "en"

static var _locale := DEFAULT_LOCALE
static var _tables: Dictionary = {}


static func get_locale() -> String:
	return _locale


static func set_locale(locale: String) -> void:
	_locale = locale
	load_locale(locale)
	if locale != FALLBACK_LOCALE:
		load_locale(FALLBACK_LOCALE)


static func load_locale(locale: String) -> bool:
	if _tables.has(locale):
		return true
	var path := "res://assets/i18n/%s.csv" % locale
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var table: Dictionary = {}
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var fields := _split_csv_line(line)
		if fields.size() >= 2 and not String(fields[0]).is_empty():
			table[String(fields[0])] = String(fields[1])
	file.close()
	_tables[locale] = table
	return true


static func text(key: String, replacements: Dictionary = {}) -> String:
	var value := _lookup(key)
	if not replacements.is_empty():
		for placeholder in replacements:
			value = value.replace("{%s}" % placeholder, str(replacements[placeholder]))
	return value


static func has_key(key: String) -> bool:
	return _lookup_raw(key) != ""


static func _lookup(key: String) -> String:
	var value := _lookup_raw(key)
	if value != "":
		return value
	return key


static func _lookup_raw(key: String) -> String:
	var table: Dictionary = _tables.get(_locale, {})
	if table.has(key):
		return String(table[key])
	var fallback: Dictionary = _tables.get(FALLBACK_LOCALE, {})
	if fallback.has(key):
		return String(fallback[key])
	return ""


## Minimal CSV split honoring double-quoted fields and "" escapes.
static func _split_csv_line(line: String) -> PackedStringArray:
	var fields := PackedStringArray()
	var current := ""
	var in_quotes := false
	var i := 0
	while i < line.length():
		var ch := line[i]
		if in_quotes:
			if ch == '"':
				if i + 1 < line.length() and line[i + 1] == '"':
					current += '"'
					i += 1
				else:
					in_quotes = false
			else:
				current += ch
		else:
			if ch == '"':
				in_quotes = true
			elif ch == ",":
				fields.append(current)
				current = ""
			else:
				current += ch
		i += 1
	fields.append(current)
	return fields
