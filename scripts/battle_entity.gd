extends CharacterBody2D
class_name BattleEntity

@export_category("Base Stats")
@export var entity_name: String = "Unknown"
@export var max_health: int = 10
@export var current_health: int = 10
@export var attack_power: int = 2

signal health_changed(current: int, max_hp: int)
signal fainted

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	print("[", entity_name, "] took ", amount, " damage. HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	emit_signal("fainted")
	print("[", entity_name, "] has fainted!")
	# We can use queue_free() here or trigger an animation first later
	queue_free()
