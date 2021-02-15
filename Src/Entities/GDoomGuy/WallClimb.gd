extends Node

export(float) var wall_climb_ray_cast_length := 2.5
export(float) var wall_climb_dash_speed := 7.0
export(float) var wall_climb_stick_gravity := 10.0

var time: float

enum { StartWallClimbing, WallClimbing, StopWallClimbing, NotWallClimbing }
var to_string = {StartWallClimbing: "StartWallClimbing", WallClimbing: "WallClimbing", StopWallClimbing: "StopWallClimbing", NotWallClimbing: "NotWallClimbing"}

var wall_climb_state: int = NotWallClimbing
var gravity_scale: float

var wall: Object
var wall_point: Vector3
var wall_normal: Vector3

func get_wall_climb_state_string():
	return to_string[wall_climb_state]

func _ready() -> void:
	# Dbg.stats.add_stat("wall_climb_state", self, "get_wall_climb_state_string", true)
	pass

func apply_movement(player: RigidBody):
	var input = player.player_input
	var direction: Vector3 = player.get_move_direction()
	var physics_state: PhysicsDirectBodyState = player.physics_state
	var wall_climb_ray_cast: RayCast = player.wall_climb_ray_cast
	var delta := physics_state.get_step()
	time += delta
	
	var velocity := physics_state.get_linear_velocity()
	
	match wall_climb_state:
		StartWallClimbing:
			gravity_scale = player.gravity_scale
			print(gravity_scale)
			player.gravity_scale = 0.0
			player.use_movement = false
			player.use_dash = false
			var dir: Vector3 = wall_point - player.global_transform.origin
			var wall_index: int= player.get_best_wall_index()
			if wall_index != -1:
				wall_climb_state = WallClimbing
			else:
				velocity = dir * wall_climb_dash_speed
			pass
		WallClimbing:
			# do movement on wall
			velocity.x = input.movement.x
			velocity.y = input.movement.z
			# stick to the wall
			velocity += -wall_normal * wall_climb_stick_gravity * delta
			if input.jump:
				wall_climb_state = StopWallClimbing
				pass
			pass
		StopWallClimbing:
			velocity = wall_normal * 7.0
			print(gravity_scale)
			player.gravity_scale = gravity_scale
			player.use_movement = true
			player.use_dash = true
			wall_climb_state = NotWallClimbing
			pass
		NotWallClimbing:
			wall_climb_ray_cast.transform.basis = player.camera.get_basis()
			# wall_climb_ray_cast.transform.origin = player.camera.transform.origin
			wall_climb_ray_cast.cast_to = Vector3.FORWARD * wall_climb_ray_cast_length
			# wall_climb_ray_cast.collision_mask = PhysicsLayers.WallClimb
			if input.interact and wall_climb_ray_cast.is_colliding():
				wall = wall_climb_ray_cast.get_collider()
				wall_point = wall_climb_ray_cast.get_collision_point()
				wall_normal = wall_climb_ray_cast.get_collision_normal()
				wall_climb_state = StartWallClimbing
			pass
	
	physics_state.set_linear_velocity(velocity)
