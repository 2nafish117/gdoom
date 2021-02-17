extends Node

export(float) var wall_climb_ray_cast_length := 4.0 # ray along which you can check for a wall to climb
export(float) var wall_climb_dash_speed := 15.0 # speed at which you dash towards wall if youre not in contatc with wall yet
export(float) var wall_climb_push_speed := 8.0 # speed added when you jump away from wall
export(float) var wall_climb_stick_gravity := 10.0 # add this bit of acceleration towards wall to stick on it

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
	Dbg.stats.add_stat("wall_climb_state", self, "get_wall_climb_state_string", true)
	pass

func apply_movement(player: RigidBody):
	var input = player.player_input
	var direction: Vector3 = player.get_move_direction()
	var physics_state: PhysicsDirectBodyState = player.physics_state
	var delta := physics_state.get_step()
	time += delta
	
	var velocity := physics_state.get_linear_velocity()
	
	match wall_climb_state:
		NotWallClimbing:
			var state_space := player.get_world().direct_space_state
			var from: Vector3 = player.camera.global_transform.origin
			var to: Vector3 = from - player.camera.get_basis().z * wall_climb_ray_cast_length
			var result := state_space.intersect_ray(from, to, [], PhysicsLayers.WallClimb)
			if input.interact and result:
				wall = result.collider
				wall_point = result.position
				wall_normal = result.normal
				wall_climb_state = StartWallClimbing
				player.use_movement = false
				player.use_dash = false
				gravity_scale = player.gravity_scale
				player.gravity_scale = 0.0
			pass
		StartWallClimbing:
			var dir: Vector3 = wall_point - player.global_transform.origin
			var wall_index: int = player.get_best_wall_index()
			var floor_index: int = player.get_best_floor_index()
			if wall_index != -1:
				wall_climb_state = WallClimbing
				# @TODO: is this fine? or make a function?
				player.movement.jump_count = 0
				player.dash.dash_count = player.dash.max_dash_count
				player.camera.camera_mode = player.camera.CamModeWallClimb
				player.camera.wall_normal = wall_normal
			else:
				velocity = dir * wall_climb_dash_speed
			pass
		WallClimbing:
			# do movement on wall
			# wall_normal
			var state_space := player.get_world().direct_space_state
			var from: Vector3 = player.camera.global_transform.origin
			var to: Vector3 = from - wall_normal * wall_climb_ray_cast_length
			var result := state_space.intersect_ray(from, to, [], PhysicsLayers.WallClimb)
			if result:
				var right: Vector3 = Vector3.UP.cross(wall_normal)
				var up: Vector3 = wall_normal.cross(right)
				right = right.normalized()
				up = up.normalized()
				velocity = 1.5 * (input.movement.x * right - input.movement.z * up)
				# stick to the wall
				velocity += -wall_normal * wall_climb_stick_gravity * delta
			else:
				wall_climb_state = NotWallClimbing
				player.movement.jump_time = player.movement.time
				player.gravity_scale = gravity_scale
				player.use_movement = true
				player.use_dash = true
				player.camera.camera_mode = player.camera.CamModeNormal
				player.camera.wall_normal = Vector3.ZERO
			if input.jump:
				wall_climb_state = NotWallClimbing
				var look_dir: Vector3 = -player.camera.get_basis().z
				# give push along wall_normal but mainly along look_dir?
				velocity = (wall_normal * 0.3 + look_dir * 0.7).normalized() * wall_climb_push_speed
				player.movement.jump_time = player.movement.time
				player.gravity_scale = gravity_scale
				player.use_movement = true
				player.use_dash = true
				player.camera.camera_mode = player.camera.CamModeNormal
				player.camera.wall_normal = Vector3.ZERO
			pass
	
	physics_state.set_linear_velocity(velocity)
