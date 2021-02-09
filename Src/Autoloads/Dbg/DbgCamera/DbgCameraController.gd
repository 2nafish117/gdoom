extends Position3D
class_name DbgCameraController

const SENS_FACTOR := 0.01

export(float) var hsens := 0.10
export(float) var vsens := 0.10
export(bool) var capture_mouse := true setget set_capture_mouse
export(float) var speed_move := 1.0

onready var camera := $H/V/Camera

func get_hbasis() -> Basis:
	return $H.global_transform.basis

func get_basis() -> Basis:
	return $H/V.global_transform.basis

# DOES NOT WORK YET, DO NOT USE!!
func set_basis(b: Basis):
	$H/V.global_transform.basis = b
	$Interpolation3D.forget_previous_transforms()
	
func set_global_position(p: Vector3):
	global_transform.origin = p
	$Interpolation3D.forget_previous_transforms()

func get_hrot() -> float:
	return $H.rotation.y

func get_vrot() -> float:
	return $H/V.rotation.x

func set_current(val: bool):
	camera.current = val

func set_capture_mouse(val: bool):
	capture_mouse = val
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready() -> void:
	set_capture_mouse(true)
	

func _physics_process(delta: float) -> void:
	var x = get_basis().x
	var y = get_basis().y
	var z = get_basis().z
	
	var input = Vector3.ZERO
	input.x = Input.get_action_strength("debug_cam_right") - Input.get_action_strength("debug_cam_left")
	input.y = Input.get_action_strength("debug_cam_up") - Input.get_action_strength("debug_cam_down")
	input.z = Input.get_action_strength("debug_cam_back") - Input.get_action_strength("debug_cam_front")
	input = input.normalized()
	
	translate(x * input.x * delta * speed_move)
	translate(y * input.y * delta * speed_move)
	translate(z * input.z * delta * speed_move)
	
	# DO NOT WRITE MOEMENT CODE BELOW THIS LINE
	# NEEDED FOR INTERPOLATION
	#$Interpolation3D.copy_current_transform()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN:
			speed_move -= 0.2
		if event.button_index == BUTTON_WHEEL_UP:
			speed_move += 0.2
		speed_move = clamp(speed_move, 0.0, 500.0)
	
	if event.is_action_pressed("ui_cancel"):
		set_capture_mouse(!capture_mouse)
		
	if event is InputEventMouseMotion:
		var hrot := -event.relative.x as float
		var vrot := -event.relative.y as float
		$H.rotate_y(hrot * hsens * SENS_FACTOR)
		$H/V.rotate_x(vrot * vsens * SENS_FACTOR)
		$H/V.rotation.x = clamp($H/V.rotation.x, -PI * 0.49, PI * 0.49)
