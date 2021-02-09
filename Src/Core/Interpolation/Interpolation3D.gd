extends Node
class_name Interpolation3D
# TODO: rotations and scaling at the same time dont work, maybe ?

# This node interpolates the parent objects transform and sets the targets transform
# as the interpolated value in 3D

export(NodePath) var target_path # sets what node to interpolate
export(bool) var enable_interpolation := true setget set_enable_interpolation

# enabling means you dont have to manually copy_current_transform() at the end of the parents _physics_process
# but gives you one frame delay, because it has to use the transforms before movment for the current physics frame
# basically allows for a drag and drop .. just works .. feature for this node
export(bool) var just_work_mode := false setget set_just_work_mode

func set_just_work_mode(val: bool):
	just_work_mode = val
	set_physics_process(just_work_mode)

func set_enable_interpolation(val: bool):
	enable_interpolation = val
	set_process(enable_interpolation)
	set_physics_process(just_work_mode)

var last_transforms := [Transform(), Transform()]
var new_transform_index := 0
var initial_target_transform: Transform

onready var target: Spatial
onready var parent := get_parent()

func _ready() -> void:
	forget_previous_transforms()
	set_process(enable_interpolation)
	set_physics_process(just_work_mode)

	if target_path != null:
		target = get_node(target_path)
		if target != null:
			initial_target_transform = target.transform
		else:
			set_enable_interpolation(false)
	else:
		set_enable_interpolation(false)
		

# use whenever teleporting the scene, to not interpolate
func forget_previous_transforms():
	last_transforms[0] = parent.global_transform
	last_transforms[1] = parent.global_transform
	new_transform_index = 0

func _process(_delta: float) -> void:
	set_interpolated_transform()

func _physics_process(_delta: float) -> void:
	copy_current_transform()

func set_interpolated_transform():
	var newest_transform := last_transforms[new_transform_index] as Transform
	var older_transform := last_transforms[old_transform_index()] as Transform
	var fraction = Engine.get_physics_interpolation_fraction()
	var parent_interpolated_transform := older_transform.interpolate_with(newest_transform, fraction)
	target.global_transform = initial_target_transform * parent_interpolated_transform

# should be called in the start of target's _fixed_update
# go back to state before interpolations
func reset_old_transform():
	var newest_transform = last_transforms[new_transform_index]
	target.global_transform = newest_transform

# should be called in the end of target's _fixed_update
func copy_current_transform():
	new_transform_index = old_transform_index()
	last_transforms[new_transform_index] = parent.global_transform

func old_transform_index():
	return (new_transform_index + 1) % 2
