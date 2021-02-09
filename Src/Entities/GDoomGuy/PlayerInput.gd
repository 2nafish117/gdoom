extends Node

export(float) var queue_jump_time := 0.16
export(float) var interact_time := 0.2

var movement: Vector3
var jump: bool
var queue_jump: bool
var dash: bool
var interact: float

var fire_primary_just_pressed: bool
var fire_primary_pressed: bool
var fire_primary_just_released: bool

var fire_secondary_just_pressed: bool
var fire_secondary_pressed: bool
var fire_secondary_just_released: bool

onready var time := 0.0
onready var jump_time := 0.0

func update(delta: float):
	time += delta
	
	movement = Vector3(
		+Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0.0,
		-Input.get_action_strength("move_front") + Input.get_action_strength("move_back")
	)
	movement = movement.normalized()
	
	jump = Input.is_action_just_pressed("action_jump")
	if jump:
		jump_time = time
		queue_jump = true
	if time - jump_time > queue_jump_time:
		queue_jump = false
	
	if Input.is_action_pressed("action_interact"):
		interact += delta / interact_time
		interact = clamp(interact, 0.0, 1.0)
	else:
		interact = 0.0
	
	dash = Input.is_action_just_pressed("action_dash")
	
	fire_primary_just_pressed = Input.is_action_just_pressed("fire_primary")
	fire_primary_pressed = Input.is_action_pressed("fire_primary")
	fire_primary_just_released = Input.is_action_just_released("fire_primary")

	fire_secondary_just_pressed = Input.is_action_just_pressed("fire_secondary")
	fire_secondary_pressed = Input.is_action_pressed("fire_secondary")
	fire_secondary_just_released = Input.is_action_just_released("fire_secondary")
	
