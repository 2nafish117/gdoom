extends MultiMeshInstance

func _on_Timer_timeout() -> void:
	queue_free()
