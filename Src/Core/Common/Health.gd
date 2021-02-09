extends Node

signal health_damaged
signal health_healed
signal health_depleted
signal health_replenished

export(float) var max_health := 100.0
export(float) var damage_multiplier := 1.0

onready var health := max_health

func is_health_depleted() -> bool:
	return health > 0.0

func reset() -> void:
	health = max_health
	emit_signal("health_replenished")

func instakill() -> void:
	health = 0.0
	emit_signal("health_depleted")

func damage(amount: float) -> float:
	amount *= damage_multiplier
	assert(amount >= 0.0)
	emit_signal("health_damaged", [amount])
	health -= amount
	if health <= 0.0:
		emit_signal("health_depleted")
	health = clamp(health, 0.0, max_health)
	return health
	
func heal(amount: float) -> float:
	assert(amount >= 0.0)
	emit_signal("health_healed", [amount])
	health += amount
	if health >= max_health:
		emit_signal("health_replenished")
	health = clamp(health, 0.0, max_health)
	return health
