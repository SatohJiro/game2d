class_name ContentId
extends RefCounted

const VALID_PATTERN := "^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$"


static func is_valid(value: StringName) -> bool:
	var text := String(value)
	if text.is_empty():
		return false
	var expression := RegEx.new()
	if expression.compile(VALID_PATTERN) != OK:
		return false
	return expression.search(text) != null


static func make(domain: String, local_name: String) -> StringName:
	var candidate := StringName("%s.%s" % [domain, local_name])
	return candidate if is_valid(candidate) else &""


static func domain_of(value: StringName) -> StringName:
	if not is_valid(value):
		return &""
	return StringName(String(value).get_slice(".", 0))


static func local_name_of(value: StringName) -> StringName:
	if not is_valid(value):
		return &""
	var text := String(value)
	return StringName(text.substr(text.find(".") + 1))
