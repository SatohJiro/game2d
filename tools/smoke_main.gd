extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Unable to load %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	var main_scene := packed_scene.instantiate()
	root.add_child(main_scene)
	for frame in range(120):
		await process_frame

	root.remove_child(main_scene)
	main_scene.free()
	main_scene = null
	packed_scene = null
	for child in root.get_children():
		child.free()
	await process_frame
	await process_frame
	_finish.call_deferred()


func _finish() -> void:
	quit(0)
