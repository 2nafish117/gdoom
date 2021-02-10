extends Spatial

export(float) var force := 2100.0

func _on_Area_body_entered(body: Node) -> void:
	var direction := global_transform.basis.y
	if body is RigidBody:
		if body.has_method("on_used_jump_pad"):
			body.call("on_used_jump_pad", direction, force)
		else:
			var velocity: Vector3 = body.linear_velocity
			velocity = velocity - velocity.project(direction)
			body.linear_velocity = velocity
			body.apply_central_impulse(force * direction)
