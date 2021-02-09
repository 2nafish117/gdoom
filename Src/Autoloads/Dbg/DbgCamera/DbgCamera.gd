extends Control

export(PackedScene) var DebugCamera3D: PackedScene
export(PackedScene) var DebugCamera2D: PackedScene

var active_camera: Camera
var dbg_cam

func spawn_camera():
	var scene := get_tree().current_scene
	if scene is Node2D:
		# TODO and TO test
		dbg_cam = DebugCamera2D.instance()
		scene.add_child(dbg_cam)
		dbg_cam.global_position = active_camera.global_position
		dbg_cam.set_current(true)
	else:
		active_camera = get_viewport().get_camera()
		dbg_cam = DebugCamera3D.instance()
		scene.add_child(dbg_cam)
		dbg_cam.set_global_position(active_camera.global_transform.origin)
		dbg_cam.set_current(true)
		active_camera.current = false
	
func despawn_camera():
	dbg_cam.set_current(false)
	if not (get_tree().current_scene is Node2D):
		active_camera.current = true
	dbg_cam.queue_free()
