extends Node

# --- Signals for UI and Game Systems ---
signal health_changed(current_health: int, max_health: int)
signal battle_health_changed(current_battle_health: int, max_battle_health: int)
signal magic_changed(current_magic: int, max_magic: int)
signal gold_changed(total_gold: int)
signal milo_defeated

# --- Core Stats (Overworld) ---
var max_health: int = 6
var current_health: int = max_health:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health <= 0:
			milo_defeated.emit()

# --- Core Stats (Battle System) ---
var max_battle_health: int = 20
var current_battle_health: int = max_battle_health:
	set(value):
		current_battle_health = clampi(value, 0, max_battle_health)
		battle_health_changed.emit(current_battle_health, max_battle_health)
		if current_battle_health <= 0:
			milo_defeated.emit()

# --- Magic & Resource Stats ---
var max_magic: int = 20
var current_magic: int = max_magic:
	set(value):
		current_magic = clampi(value, 0, max_magic)
		magic_changed.emit(current_magic, max_magic)

# --- Progression & Currencies ---
var gold: int = 0:
	set(value):
		gold = max(0, value) # Prevents negative gold
		gold_changed.emit(gold)

var current_level: int = 1

# --- Combat Specific Stats ---
var attack_power: int = 3
var armor_class: int = 11
var is_defending: bool = false

func _ready() -> void:
	print("PlayerStateManager: System initialized.")

# --- Public Methods (API) ---

func consume_magic(amount: int) -> bool:
	if current_magic >= amount:
		current_magic -= amount
		return true
	print("[PlayerStateManager] Not enough magic!")
	return false


func restore_magic(amount: int) -> void:
	current_magic += amount


func take_damage(amount: int, is_overworld: bool = false) -> void:
	var final_damage: int = amount
	
	# Overworld damage (Hearts system interaction)
	if is_overworld:
		current_health -= final_damage
		print("[PlayerStateManager] Milo took damage in Overworld. Hearts left: ", current_health)
		return
		
	# Battle health takes priority during combat rounds
	if is_defending:
		final_damage = max(1, int(amount / 2.0))
		print("[PlayerStateManager] Milo mitigated damage from ", amount, " to ", final_damage)
		
	current_battle_health -= final_damage
	print("[PlayerStateManager] Milo took damage in battle. Current battle health: ", current_battle_health)


func heal(amount: int) -> void:
	current_battle_health += amount


## Restores Milo's combat health to maximum at the start of a battle encounter
func reset_battle_health() -> void:
	current_battle_health = max_battle_health
