tool
extends Area
export(NodePath) var destination_path
export(float) var destination_offset := 2.0
export(float) var radius := 1.0 setget set_radius
export(float) var depth := 0.5 setget set_depth

onready var collision := $CollisionShape
onready var mesh := $MeshInstance

func set_radius(val: float) -> void:
	radius = val
	if collision != null and collision.shape != null:
		collision.shape.radius = radius
	property_list_changed_notify()
	
func set_depth(val: float) -> void:
	depth = val
	if collision != null and collision.shape != null:
		collision.shape.height = depth
	property_list_changed_notify()

var destination: Spatial

func _ready() -> void:
	destination = get_node_or_null(destination_path)

func _on_Portal_body_entered(body: Node) -> void:
	if body.is_in_group("portalable") and destination != null:
		var xform: Transform
		xform.origin = destination.global_transform.origin - destination.global_transform.basis.z * destination_offset
		xform.basis = destination.transform.basis
		body.set_global_transform(xform)
