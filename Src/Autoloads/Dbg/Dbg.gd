extends CanvasLayer

onready var stats := $DbgStats 
onready var draw := $DbgDraw
onready var camera := $DbgCamera
onready var console := $DbgConsole

export(bool) var show_debug_stats := true setget set_show_debug_stats
export(bool) var show_debug_draw := true setget set_show_debug_draw
export(bool) var show_debug_camera := false setget set_show_debug_camera
export(bool) var show_debug_console := false setget set_show_debug_console

func _ready() -> void:
	set_show_debug_stats(true)
	set_show_debug_draw(true)
	set_show_debug_console(false)
	add_debug_keybind("toggle_debug_stats", KEY_F1)
	add_debug_keybind("toggle_debug_draw", KEY_F2)
	add_debug_keybind("toggle_debug_camera", KEY_F3)
	add_debug_keybind("toggle_debug_console", KEY_QUOTELEFT)
	
	add_debug_keybind("debug_cam_front", KEY_I)
	add_debug_keybind("debug_cam_left", KEY_J)
	add_debug_keybind("debug_cam_back", KEY_K)
	add_debug_keybind("debug_cam_right", KEY_L)
	add_debug_keybind("debug_cam_up", KEY_U)
	add_debug_keybind("debug_cam_down", KEY_O)

func set_show_debug_stats(val: bool) -> void:
	show_debug_stats = val
	stats.visible = val

func set_show_debug_draw(val: bool) -> void:
	show_debug_draw = val
	draw.visible = val
	# get_tree().set_debug_collisions_hint(val)
	# get_tree().is_debugging_collisions_hint()

func set_show_debug_camera(val: bool) -> void:
	show_debug_camera = val
	if val:
		camera.spawn_camera()
	else:
		camera.despawn_camera()

func set_show_debug_console(val: bool) -> void:
	show_debug_console = val
	console.visible = val
	if val:
		console.on_activate()
		pass
	else:
		console.on_deactivate()
		pass

func add_debug_keybind(action_name: String, toggle_key: int):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev = InputEventKey.new()
		ev.scancode = toggle_key
		InputMap.action_add_event(action_name, ev)
	else:
		InputMap.action_erase_events(action_name)
		InputMap.add_action(action_name)
		var ev = InputEventKey.new()
		ev.scancode = toggle_key
		InputMap.action_add_event(action_name, ev)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_stats"):
		set_show_debug_stats(!show_debug_stats)
	elif event.is_action_pressed("toggle_debug_draw"):
		set_show_debug_draw(!show_debug_draw)
	elif event.is_action_pressed("toggle_debug_camera"):
		set_show_debug_camera(!show_debug_camera)
	elif event.is_action_pressed("toggle_debug_console"):
		set_show_debug_console(!show_debug_console)
		get_tree().set_input_as_handled()
