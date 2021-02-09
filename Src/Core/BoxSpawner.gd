extends Position3D

export(PackedScene) var ITEM: PackedScene
export(float) var SPAWN_FORCE := 400.0
export(int) var SIMULTANEOUS_SPAWNED_NUMBER := 10.0

onready var items := []

func spawn_box():
	var item = ITEM.instance() as RigidBody
	add_child(item)
	item.transform = Transform()
	item.apply_central_impulse(-global_transform.basis.z * SPAWN_FORCE)
	items.push_back(item)

func despawn_box():
	var item = items.pop_front()
	item.queue_free()

func _on_SpawnTimer_timeout() -> void:
	if len(items) > SIMULTANEOUS_SPAWNED_NUMBER:
		despawn_box()
	spawn_box()
