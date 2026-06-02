extends Node

# --- Preloaded Scenes ---
const DIALOGUE_SCREEN: PackedScene = preload("res://scenes/dialog_screen.tscn")

# DIALOG HUD (A instância da janela de diálogo)
var dialogue_hud: Control = null

func _ready() -> void:
	print("DialogManager: System initialized.")

# Loads the dialog screen dentro da GUI global
func load_dialog_hud(global_gui: CanvasLayer) -> void:
	if not global_gui:
		print("[DialogManager] Error: Cannot load Dialog HUD because global_gui is null!")
		return
		
	if not dialogue_hud:
		dialogue_hud = DIALOGUE_SCREEN.instantiate() as Control
		dialogue_hud.position = Vector2(240, 250)
		global_gui.add_child(dialogue_hud)
		print("[DialogManager] Dialog HUD instantiated and added to GUI.")

# Start the dialog with an NPC
func start_dialogue(lines: Array[String], portrait: Texture2D) -> void:  
	print("[DialogManager] Starting dialog...")
	
	# Lock Milo while talking (Acessando o Milo via GameManager que ainda gerencia o player)
	if GameManager.milo: 
		GameManager.milo.set_physics_process(false)
		
	# Certifica-se de que o HUD existe antes de chamar a função dele
	if dialogue_hud:
		dialogue_hud.start_dialogue(lines, portrait)
	else:
		print("[DialogManager] Error: dialogue_hud is missing! Did you call load_dialog_hud?")

# Função utilitária para quando o diálogo terminar (para ser chamada pelo próprio script do dialog_screen)
func end_dialogue() -> void:
	print("[DialogManager] Dialog finished.")
	if GameManager.milo:
		GameManager.milo.set_physics_process(true)
