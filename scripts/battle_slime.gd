extends BattleEntity
# Notice we don't need class_name here unless you want to, 
# and it automatically inherits HP, attack, and take_damage!

func _ready() -> void:
	$Sprite.play("idle")

	entity_name = "Slime"
	max_health = 6
	current_health = max_health
	attack_power = 2
	print("[BattleSlime] Ready for combat!")


func _on_sprite_animation_finished() -> void:
	if $Sprite.animation == "attack":
		var tween_back: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Go back
		tween_back.tween_property(self, "global_position", original_battle_position, 0.25)

		# Este callback só vai rodar DEPOIS que a movimentação acima terminar
		tween_back.tween_callback(func():
			is_attacking = false
			$Sprite.play("idle")
		)
