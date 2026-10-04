class_name PlayerNeedsTickResult
extends RefCounted

var snapshot: PlayerNeedsSnapshot
var buff_expired: bool


func _init(current_snapshot: PlayerNeedsSnapshot, did_buff_expire: bool = false) -> void:
	snapshot = current_snapshot
	buff_expired = did_buff_expire
