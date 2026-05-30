extends Node2D

# --- Configuration ---
# Pointing directly to your actual scene file path inside the scenes folder
@export_file("*.tscn") var initial_level_path: String = "res://scenes/level_1.tscn"

func _ready() -> void:
	_boot_game()

# Handles the initial setup and handoff to the global GameManager
func _boot_game() -> void:
	print("Main: Booting game systems...")
	
	# Fallback safety check in case the export path was left empty in the Inspector
	if initial_level_path.is_empty():
		initial_level_path = "res://scenes/level_1.tscn"
		
	print("Main: Handing over control to GameManager.")
	
	# Pass this main node to GameManager
	# so it can attach the level and GUI to it
	GameManager.start_game(self)
