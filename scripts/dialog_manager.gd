## Coordinates dialogue orchestration, freezing gameplay inputs, and spawning overlay screens.
extends Node

## Preloaded scene reference for the screen interface
const DIALOGUE_SCREEN: PackedScene = preload("res://scenes/dialog_screen.tscn")

## Active runtime reference instance of the dialog canvas box UI
var dialogue_hud: Control = null

func _ready() -> void:
	print("DialogManager: System initialized.")

## Loads the dialog screen layout inside the global game GUI container layer layout.
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

func start_dialogue(npc_name: String, portrait: Texture2D) -> void:  
	print("[DialogManager] Starting custom structured data conversation...")
	
	# Freeze Milo's environment interactions completely while chatting
	if is_instance_valid(GameManager.milo): 
		GameManager.milo.set_physics_process(false)
		
	# Ensure HUD instance is active and pass the presentation data down
	if not is_instance_valid(dialogue_hud):
		load_dialog_hud()
		
	if is_instance_valid(dialogue_hud):
		# We forward the data directly to the visual interface
		dialogue_hud.start_dialogue(npc_name, portrait)
	else:
		print("[DialogManager] Critical Error: Failed to instantiate dialogue_hud overlay screen.")

## Restores player physics controls back to operational behavior states upon close triggers.
func end_dialogue() -> void:
	print("[DialogManager] Dialogue finished.")
	
	# Cache global layer references before cleaning up control focus
	var ui_canvas = GameManager.global_gui
	
	if is_instance_valid(GameManager.milo):
		GameManager.milo.set_physics_process(true)
		
	# CHECK TRIGGERED REWARDS: If Milo won an item, open up the inventory interface overlay
	if HistoryManager.should_open_inventory and ui_canvas:
		print("[DialogManager] Reward detected! Automatically presenting the inventory screen UI.")
		
		# A) UNLOCK HUD BUTTON: Safely reveal and enable your inventory HUD element if it exists
		if ui_canvas.has_node("InventoryButton"):
			ui_canvas.get_node("InventoryButton").disabled = false
			ui_canvas.get_node("InventoryButton").show()
		
		# B) SHOW INVENTORY WINDOW: Force toggle presentation to display the newly added items
		if ui_canvas.has_node("InventoryUI"):
			ui_canvas.get_node("InventoryUI").toggle()
			
		# Reset the condition flag state to prevent repeating hooks loop execution
		HistoryManager.should_open_inventory = false
