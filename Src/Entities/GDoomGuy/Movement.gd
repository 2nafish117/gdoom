extends Node

export(float) var accel_ground := 80.0
export(float) var accel_air := 40.0 # 30.0

export(float) var friction_ground := 10.0
export(float) var friction_air := 0.0

export(float) var speed_ground := 6.0
export(float) var speed_stop := 1.0
export(float) var speed_air := 6.0
export(float) var speed_jump := 6.0
export(int) var air_jump_count := 1
export(float) var time_jump_cooldown := 0.2

export(float) var ground_stick_gravity_multiplier := 3.0

# modifiers (use them to vary their values from the outside)
var accel_ground_modifier := 1.0
var accel_air_modifier := 1.0
var friction_ground_modifier := 1.0
var friction_air_modifier := 1.0
var speed_ground_modifier := 1.0
var speed_air_modifier := 1.0
var speed_jump_modifier := 1.0
var jump_count := 0
var ground_stick_gravity_modifier := 1.0

var time := 0.0
var jump_time := 0.0

var floor_velocity : Vector3
var floor_normal: Vector3
var floor_contact: Vector3

var floor_in_contact: bool
var floor_in_proximity: int = 0

func accelerate(direction: Vector3, velocity: Vector3, max_accel: float, max_speed: float, delta: float) -> Vector3:
	var projection := velocity.dot(direction)
	var add_speed := max_speed - projection
	add_speed = clamp(add_speed, 0.0, max_accel * delta)
	
	# this applies friction perpendicular to direction of movement, making controls feel like doom 2016 with air control
	if direction != Vector3.ZERO:
		var vel_along_direction := velocity.project(direction)
		var vel_perp_direction := velocity - vel_along_direction
		var speed_perp_direction := vel_perp_direction.length()
		if speed_perp_direction != 0.0:
			var control := max(1.0, speed_perp_direction * 0.9)
			# var control := 0.2
			var drop := control * 2.0 * delta
			vel_perp_direction *= max(speed_perp_direction - drop, 0.0) / speed_perp_direction

		velocity = vel_along_direction + vel_perp_direction
	
	return velocity + direction * add_speed

# returns velocity after applying friction
func friction(velocity: Vector3, friction: float, _speed_stop: float, delta: float) -> Vector3:
	var speed := velocity.length()
	if speed != 0.0:
		var control := max(_speed_stop, speed)
		var drop := control * friction * delta
		velocity *= max(speed - drop, 0.0) / speed
	return velocity

func apply_movement(player: RigidBody):
	var input = player.player_input
	var direction: Vector3 = player.get_move_direction()
	var physics_state: PhysicsDirectBodyState = player.physics_state
	# var state_space := player.get_world().direct_space_state
	# var floor_indices: Array = player.floor_contact_indices
	# var wall_indices: Array = player.wall_contact_indices
	var delta := physics_state.get_step()
	time += delta
	
	var gravity := physics_state.get_total_gravity()
	var velocity := physics_state.get_linear_velocity()
	floor_in_contact = player.floor_in_contact()

	if floor_in_contact:
		var floor_index: int = player.get_best_floor_index()
		
		var object = physics_state.get_contact_collider_object(floor_index)
		if object != null:
			floor_contact = object.global_transform.origin + physics_state.get_contact_local_position(floor_index)
		floor_normal = physics_state.get_contact_local_normal(floor_index)

		# Deapply previous frame floor velocity
		velocity -= floor_velocity
		
		# check jump
		jump_count = 0
		if input.queue_jump:
			if time - jump_time >= time_jump_cooldown:
				jump_count += 1
				velocity.y = speed_jump_modifier * speed_jump
				jump_time = time
		else:
			# only apply ground stick gravity if not on rigidbodies
			if object != null and (not (object is RigidBody)) or (object is RigidBody and object.mode != RigidBody.MODE_RIGID):
				velocity += -gravity.length() * floor_normal * delta * ground_stick_gravity_modifier * ground_stick_gravity_multiplier
		
		# apply ground friction paralell to ground surface only
		var vel_perp_ground := velocity.project(floor_normal)
		var vel_along_ground := velocity - vel_perp_ground
		vel_along_ground = friction(vel_along_ground, friction_ground_modifier * friction_ground, speed_stop, delta)
		velocity = vel_along_ground + vel_perp_ground
		
		var vvel := velocity.project(Vector3.UP)
		var hvel := velocity - vvel
		hvel = accelerate(direction, hvel, accel_ground_modifier * accel_ground, speed_ground_modifier * speed_ground, delta)
		velocity = hvel + vvel
		
		# Apply floor velocity and movement
		floor_velocity = physics_state.get_contact_collider_velocity_at_position(floor_index)
		velocity += floor_velocity
	else:
		# velocity = friction(velocity, friction_air_modifier * friction_air, speed_stop, delta)
		var vvel := velocity.project(Vector3.UP)
		var hvel := velocity - vvel
		hvel = accelerate(direction, hvel, accel_air_modifier * accel_air, speed_air_modifier * speed_air, delta)
		velocity = hvel + vvel

		if input.queue_jump and time - jump_time >= time_jump_cooldown and jump_count < air_jump_count and velocity.y < speed_jump_modifier * speed_jump:
			# @TODO: coyote jump-ish
			# if floor_in_proximity <= 0:
			jump_count += 1
			jump_time = time
			velocity.y = speed_jump_modifier * speed_jump
		
		velocity += gravity * delta
		
	physics_state.set_linear_velocity(velocity)

func _on_FloorInProximityArea_body_entered(_body: Node) -> void:
	floor_in_proximity += 1

func _on_FloorInProximityArea_body_exited(_body: Node) -> void:
	floor_in_proximity -= 1
