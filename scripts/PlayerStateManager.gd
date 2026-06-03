extends Node

# --- Signals for UI and Game Systems ---
signal health_changed(current_health: int, max_health: int)
signal magic_changed(current_magic: int, max_magic: int)
signal gold_changed(total_gold: int)
signal milo_defeated

# --- Core Stats ---
var max_health: int = 6
var current_health: int = max_health:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health <= 0:
			milo_defeated.emit()

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

func take_damage(amount: int) -> void:
	current_health -= amount
	print("[PlayerStateManager] Milo took damage. Current health: ", current_health)

func heal(amount: int) -> void:
	current_health += amount
