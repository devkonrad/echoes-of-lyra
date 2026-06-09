## Specific controller for the Shield & Sword Warrior overworld enemy entity.
extends EnemyPatrolBase

@export_group("Warrior Custom Effects")
## Chance of the warrior performing a brief sword flourish or taunt when going Idle (0.0 to 1.0)
@export var taunt_chance: float = 0.35

## Overriding the state entry to trigger warrior-specific audio or visual flavor cues
func _change_state(new_state: State) -> void:
	# ALWAYS call the parent class method first so the core AI framework executes!
	super._change_state(new_state)
	
	# Add local specialized behavior hooks
	match current_state:
		State.CHASE:
			print("[EnemyWarrior] Clank! Alert status triggered. Pursuing Milo!")
			# Future home for a heavy metal armor clatter sound effect or alert visual exclamation
		State.IDLE:
			_roll_for_custom_idle_flavor()

## Local specialized feature: plays a flourish loop if the random roll hits the target chance
func _roll_for_custom_idle_flavor() -> void:
	if sprite and sprite.sprite_frames.has_animation("attack") and randf() < taunt_chance:
		# Repurposing the attack animation frames as an intimidating overworld taunt flourish
		sprite.play("attack")
		print("[EnemyWarrior] Guard is performing a defensive weapon flourish stance.")


func _on_defeated() -> void:
	""" Here we can call up custom methods, 
	such as opening a door, summoning a 
	new horde of enemies, etc...
	"""
	print("The Enemy has been defeated!")
