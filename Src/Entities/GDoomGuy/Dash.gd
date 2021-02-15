extends Node

export(float) var time_dash_cooldown := 1.5
export(float) var time_dash_duration := 0.22
export(float) var speed_dash := 20.0
export(float) var fraction_speed_conserve_after_dash := 0.22
export(int) var max_dash_count := 2

var time := 0.0
var dash_time := -time_dash_cooldown
var dash_recharge_time := 0.0

enum { StartDashing, Dashing, StopDashing, NotDashing }
var to_string = {StartDashing: "StartDashing", Dashing: "Dashing", StopDashing: "StopDashing", NotDashing: "NotDashing"}

var dash_state: int = NotDashing
var dash_count := max_dash_count
var gravity_scale: float

func get_dash_state_string():
	return to_string[dash_state]

func _ready() -> void:
	# Dbg.stats.add_stat("dash count", self, "dash_count")
	pass

func apply_movement(player: RigidBody):
	var input = player.player_input
	var direction: Vector3 = player.get_move_direction()
	var physics_state: PhysicsDirectBodyState = player.physics_state
	# var rigidbody := player
	var delta := physics_state.get_step()
	time += delta
	
	var velocity := physics_state.get_linear_velocity()
	
	match dash_state:
		StartDashing:
			dash_state = Dashing
			dash_time = time
			dash_recharge_time = time
			dash_count -= 1
			gravity_scale = player.gravity_scale
			player.gravity_scale = 0.0
			# what if player is on stairs or uneven ground? what direction
			velocity = direction * speed_dash + Vector3.UP * 0.2
		Dashing:
			# TODO: what if i hit a jumppad or launchpad?
			# ans: stop dashing immediately and do the jumppad
			if time - dash_time >= time_dash_duration:
				dash_state = StopDashing
		StopDashing:
			dash_state = NotDashing
			player.gravity_scale = gravity_scale
			velocity = fraction_speed_conserve_after_dash * velocity
		NotDashing:
			if input.movement.length_squared() > 0.01 and input.dash and dash_count > 0:
				dash_state = StartDashing
			if time - dash_recharge_time >= time_dash_cooldown and player.floor_in_contact():
				dash_recharge_time = time
				dash_count = max_dash_count
	
	physics_state.set_linear_velocity(velocity)
	
