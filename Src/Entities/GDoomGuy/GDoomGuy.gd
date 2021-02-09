extends RigidBody

export(float, 0.0, 90.0) var floor_angle := 40.0

# angle between floor normal and y-up
# 0deg to 40deg is floor
# 40deg to 90 deg is wall
onready var cos_floor_angle := cos(deg2rad(floor_angle))
onready var player_input := $PlayerInput
onready var camera := $FpCamera

var physics_state: PhysicsDirectBodyState
var floor_contact_indices := []
var wall_contact_indices := []

func get_speed() -> float:
	return linear_velocity.length()

func get_hspeed() -> float:
	return (linear_velocity - linear_velocity.project(Vector3.UP)).length()

func get_vspeed() -> float:
	return linear_velocity.project(Vector3.UP).length()

func get_move_direction() -> Vector3:
	var camera_hrot := camera.get_hrot() as float
	return player_input.movement.rotated(Vector3.UP, camera_hrot)

func get_look_direction() -> Vector3:
	return -camera.get_basis().z

func floor_in_contact() -> bool:
	return len(floor_contact_indices) > 0

func wall_in_contact() -> bool:
	return len(wall_contact_indices) > 0

func update_contact_indices(state: PhysicsDirectBodyState):
	floor_contact_indices = []
	wall_contact_indices = []
	for idx in range(state.get_contact_count()):
		var normal := state.get_contact_local_normal(idx)
		var abs_cos_theta := normal.dot(Vector3.UP)
		if abs_cos_theta >= cos_floor_angle and abs_cos_theta <= 1.0:
			floor_contact_indices.append(idx)
		elif abs_cos_theta >= 0.0 and abs_cos_theta < cos_floor_angle:
			wall_contact_indices.append(idx)

func get_best_floor_index() -> int:
	if len(floor_contact_indices) == 0:
		return -1
	var floor_index: int = floor_contact_indices[0]
	for idx in floor_contact_indices:
		if physics_state.get_contact_local_normal(idx).y > physics_state.get_contact_local_normal(floor_index).y:
			floor_index = idx
	return floor_index

func get_best_wall_index() -> int:
	if len(wall_contact_indices) == 0:
		return -1
	var wall_index: int = wall_contact_indices[0]
	for idx in wall_contact_indices:
		if physics_state.get_contact_local_normal(idx).y < physics_state.get_contact_local_normal(wall_index).y:
			wall_index = idx
	return wall_index

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	physics_state = state
	var delta := state.get_step()
	player_input.update(delta)
	update_contact_indices(state)
	
	$Movement.apply_movement(self)
	$Dash.apply_movement(self)
	# DO NOT WRITE MOVEMENT CODE BELOW THIS LINE!!!
	# IT IS NEEDED TO INTERPOLATE THE FPCamera
	# $Interpolation3D.copy_current_transform()
