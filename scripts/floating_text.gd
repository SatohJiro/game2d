extends Node2D

@onready var label: Label = $Label
var text: String = ""
var color: Color = Color.WHITE
var duration: float = 0.8
var velocity: Vector2 = Vector2(0, -45)

func _ready() -> void:
	if label:
		label.text = text
		label.modulate = color
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + velocity, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.4)
	tween.chain().tween_callback(queue_free)
