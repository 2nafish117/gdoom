extends Area

func _on_RespawnBox_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var _err := get_tree().reload_current_scene()
