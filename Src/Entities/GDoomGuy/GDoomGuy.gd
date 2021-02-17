extends RigidBody

export(float, 0.0, 90.0) var floor_angle := 40.0

# angle between floor normal and y-up
# 0deg to 40deg is floor
# 40deg to 90 deg is wall
onready var cos_floor_angle := cos(deg2rad(floor_angle))
onready var player_input := $PlayerInput
onready var camera := $FpCamera

# used by movement abilities
onready var stair_detection := $StairDetection

# movement abilities
onready var movement := get_node_or_null("Movement")
onready var use_movement := movement != null
onready var dash := get_node_or_null("Dash")
onready var use_dash := dash != null
onready var wall_climb := get_node_or_null("WallClimb")
onready var use_wall_climb := wall_climb != null

# used by the movement abilities
var physics_state: PhysicsDirectBodyState
var floor_contact_indices := []
var wall_contact_indices := []

# when dashing into a jump pad cancel the dash
func on_used_jump_pad(direction: Vector3, force: float):
	if dash == null:
		return
	if dash.dash_state == dash.Dashing or dash.dash_state == dash.StopDashing:
		dash.dash_state = dash.NotDashing
		gravity_scale = dash.gravity_scale
		linear_velocity = Vector3.ZERO
		pass
	linear_velocity = linear_velocity - linear_velocity.project(direction)
	apply_central_impulse(force * direction)

func on_used_portal():
	# @TODO
	pass

func set_global_origin(origin: Vector3) -> void:
	mode = RigidBody.MODE_KINEMATIC
	$Interpolation3D.forget_previous_transforms()
	global_transform.origin = origin
	mode = RigidBody.MODE_CHARACTER

func set_global_basis(basis: Basis) -> void:
	mode = RigidBody.MODE_KINEMATIC
	$Interpolation3D.forget_previous_transforms()
	global_transform.basis = basis
	mode = RigidBody.MODE_CHARACTER

# override parent definition
func set_global_transform(xform: Transform) -> void:
	# print("calling ovveride")
	mode = RigidBody.MODE_KINEMATIC
	$Interpolation3D.forget_previous_transforms()
	global_transform = xform
	mode = RigidBody.MODE_CHARACTER

func set_camera_global_basis(basis: Basis) -> void:
	camera.set_camera_global_basis(basis)

func get_speed() -> float:
	return linear_velocity.length()

func get_hspeed() -> float:
	return (linear_velocity - linear_velocity.project(Vector3.UP)).length()

func get_vspeed() -> float:
	return linear_velocity.project(Vector3.UP).length()

func get_move_direction() -> Vector3:
	var camera_hrot := camera.get_hrot() as float
	# also rotate the stair detection rig
	$StairDetection.global_transform.basis = camera.get_hbasis()
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
		var abs_cos_theta := abs(normal.dot(Vector3.UP))
		if abs_cos_theta >= cos_floor_angle and abs_cos_theta <= 1.0:
			floor_contact_indices.append(idx)
		elif abs_cos_theta >= 0.0 and abs_cos_theta < cos_floor_angle:
			wall_contact_indices.append(idx)

# used by movement abilities
func get_best_floor_index() -> int:
	if len(floor_contact_indices) == 0:
		return -1
	var floor_index: int = floor_contact_indices[0]
	for idx in floor_contact_indices:
		if physics_state.get_contact_local_normal(idx).y > physics_state.get_contact_local_normal(floor_index).y:
			floor_index = idx
	return floor_index

# used by movement abilities
func get_best_wall_index() -> int:
	if len(wall_contact_indices) == 0:
		return -1
	var wall_index: int = wall_contact_indices[0]
	for idx in wall_contact_indices:
		if abs(physics_state.get_contact_local_normal(idx).y) < abs(physics_state.get_contact_local_normal(wall_index).y):
			wall_index = idx
	return wall_index

func _ready() -> void:
	Dbg.stats.add_stat("hspeed", self, "get_hspeed", true)
	Dbg.stats.add_stat("vspeed", self, "get_vspeed", true)
	Dbg.stats.add_stat("speed", self, "get_speed", true)
	
	Dbg.stats.add_stat("floor_contact_indices", self, "floor_contact_indices")
	Dbg.stats.add_stat("wall_contact_indices", self, "wall_contact_indices")
	
	Dbg.draw.add_vector3d(self, "linear_velocity", false, 0.05, 4, Color(0,1,0, 0.5))
	pass

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	physics_state = state
	var delta := state.get_step()
	player_input.update(delta)
	update_contact_indices(state)
	
	if movement != null and use_movement:
		movement.apply_movement(self)
	if dash != null and use_dash:
		dash.apply_movement(self)
	if wall_climb != null and use_wall_climb:
		wall_climb.apply_movement(self)
	
	# DO NOT WRITE MOVEMENT CODE BELOW THIS LINE!!!
	# IT IS NEEDED TO INTERPOLATE THE FPCamera
	# $Interpolation3D.copy_current_transform()
