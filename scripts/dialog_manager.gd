extends Node

# --- Preloaded Scenes ---
const DIALOGUE_SCREEN: PackedScene = preload("res://scenes/dialog_screen.tscn")

# DIALOG HUD (The dialog window instance)
var dialogue_hud: Control = null

func _ready() -> void:
	print("DialogManager: System initialized.")

# Loads the dialog screen inside the global GUI
func load_dialog_hud() -> void:
	if not is_instance_valid(GameManager.global_gui):
		print("[DialogManager] Error: Cannot load Dialog HUD because target GUI is null!")
		return
		
	if not is_instance_valid(dialogue_hud):
		dialogue_hud = DIALOGUE_SCREEN.instantiate() as Control
		
		# Position setup (Centered at the bottom area of your 480x270 viewport)
		dialogue_hud.position = Vector2(240, 250)
		
		GameManager.global_gui.add_child(dialogue_hud)
		print("[DialogManager] Dialog HUD instantiated and added to GUI.")

func start_dialogue(lines: Array[String], portrait: Texture2D) -> void:  
	print("[DialogManager] Starting dialogue...")
	
	if is_instance_valid(GameManager.milo): 
		GameManager.milo.set_physics_process(false)
		
	if is_instance_valid(dialogue_hud):
		dialogue_hud.start_dialogue(lines, portrait)
	else:
		print("[DialogManager] Error: dialogue_hud is missing! Initializing it on the fly...")
		load_dialog_hud()
		if dialogue_hud:
			dialogue_hud.start_dialogue(lines, portrait)

func end_dialogue() -> void:
	print("[DialogManager] Dialogue finished.")
	if is_instance_valid(GameManager.milo):
		GameManager.milo.set_physics_process(true)
