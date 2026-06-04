extends BattleEntity
# Notice we don't need class_name here unless you want to, 
# and it automatically inherits HP, attack, and take_damage!

func _ready() -> void:
	$Sprite.play("default")

	entity_name = "Slime"
	max_health = 6
	current_health = max_health
	attack_power = 2
	print("[BattleSlime] Ready for combat!")
