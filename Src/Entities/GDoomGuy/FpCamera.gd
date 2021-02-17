extends Position3D

const MOUSE_SENSITIVITY_FACTOR := 0.001

enum { CamModeNormal, CamModeWallClimb }
var camera_mode := CamModeNormal
var wall_normal: Vector3

onready var camera := $H/V/Camera
onready var offset := Vector2.ZERO
onready var prev_offset := Vector2.ZERO

onready var mouse_horizontal_sensitivity: float = 1.0
onready var mouse_vertical_sensitivity: float = 1.0

var noise: OpenSimplexNoise
var amplitude: Vector3 = Vector3(2.0, 2.0, 2.0)
var trauma: float = 0.0
var time := 0.0
var shake: Vector3


func get_hbasis() -> Basis:
	return $H.global_transform.basis

func get_basis() -> Basis:
	return $H/V.global_transform.basis

func get_hrot() -> float:
	return $H.global_transform.basis.get_euler().y

func get_vrot() -> float:
	return $H/V.global_transform.basis.get_euler().x

func set_camera_global_basis(basis: Basis) -> void:
	# global_transform.basis = basis
	# basis.get_rotation_quat()
	# $H.rotation.y += basis.get_euler().y
	# $H/V.rotation.x = 0.0
	# TODO
	pass

func set_offset(val: Vector2):
	prev_offset = offset
	offset = val

func add_offset(val: Vector2):
	prev_offset = offset
	offset += val

func camera_shake():
	var value: float
	# @INFO: magic number
	value = noise.get_noise_1d(time + 10.2)
	$H.rotation.y -= shake.y
	shake.y = amplitude.y * value * MOUSE_SENSITIVITY_FACTOR
	$H.rotation.y += shake.y

	# @INFO: magic number
	value = noise.get_noise_1d(time - 32.5)
	$H/V.rotation.x -= shake.x
	shake.x = amplitude.x * value * MOUSE_SENSITIVITY_FACTOR
	$H/V.rotation.x += shake.x
	
	# @INFO: magic number
	value = noise.get_noise_1d(time + 122.0)
	$H/V.rotation.z -= shake.z
	shake.z = amplitude.z * value * MOUSE_SENSITIVITY_FACTOR
	$H/V.rotation.z += shake.z
	
	$H/V.rotation.x = clamp($H/V.rotation.x, -PI * 0.47, PI * 0.47)

func _ready() -> void:
	noise = OpenSimplexNoise.new()
	noise.seed = 0
	noise.octaves = 1
	noise.period = 0.06
	noise.persistence = 0.5
	noise.lacunarity = 2.0

# @TODO: make it so i use unhandled input instead of controller input
func _process(delta: float) -> void:
	time += delta
	
	# camera shake stuff
	#if Input.is_action_pressed("fire_secondary"):
	#	trauma += delta
	#else:
	#	trauma -= delta
	#trauma = clamp(trauma, 0.0, 1.0)
	
	# camera_shake(trauma * trauma * amplitude, noise, time)
	# $H.rotate_y(-prev_offset.x)
	# $H/V.rotate_x(-prev_offset.y)
	# $H.rotate_y(offset.x)
	# $H/V.rotate_x(offset.y)

var k = 0.1 * PI
var theta1 := 0.0
var theta2 := 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hrot := -event.relative.x as float
		var vrot := -event.relative.y as float
		match camera_mode:
			CamModeNormal:
				$H.rotate_y(hrot * mouse_horizontal_sensitivity * MOUSE_SENSITIVITY_FACTOR)
				$H/V.rotate_x(vrot * mouse_vertical_sensitivity * MOUSE_SENSITIVITY_FACTOR)
				$H.rotation.y = fmod($H.rotation.y, PI)
				$H/V.rotation.x = clamp($H/V.rotation.x, -PI * 0.47, PI * 0.47)
				# print($H.rotation.y)
				pass
			CamModeWallClimb:
				$H.rotate_y(hrot * mouse_horizontal_sensitivity * MOUSE_SENSITIVITY_FACTOR)
				$H/V.rotate_x(vrot * mouse_vertical_sensitivity * MOUSE_SENSITIVITY_FACTOR)
				$H.rotation.y = fmod($H.rotation.y, PI)
				# print($H.rotation.y)
				$H/V.rotation.x = clamp($H/V.rotation.x, -PI * 0.47, PI * 0.47)
				
				# WTF how is clamping aross horizontal such a hard fucking thing to do?
				var horizontal_view_dir := -get_hbasis().z
				wall_normal.y = 0.0
				wall_normal = wall_normal.normalized()
				
				var wall_normal_to_right_angle := Vector3.FORWARD.angle_to(wall_normal)
				var wall_normal_cross_right_y := -Vector3.FORWARD.z * wall_normal.x + Vector3.FORWARD.x * wall_normal.z # simplified
				# print(wall_normal_cross_right_y)
				if wall_normal_cross_right_y < 0:
					theta1 = PI - wall_normal_to_right_angle + k
					theta2 = PI - wall_normal_to_right_angle - k
					pass
				else:
					theta1 = -PI + wall_normal_to_right_angle + k
					theta2 = -PI + wall_normal_to_right_angle - k
				
				theta1 = fmod(theta1, PI)
				theta2 = fmod(theta2, PI)
				# print(theta1, " ", theta2)
				if theta1 > theta2:
					var t = theta1
					theta1 = theta2
					theta2 = t
				if $H.rotation.y > theta1 and $H.rotation.y < theta2:
					print("clamped")
				# $H.rotation.y = clamp($H.rotation.y, from, to)
				pass
		
