extends Node

# --- Preloaded Scenes (Assets) ---
const UI_SCENE: PackedScene = preload("res://scenes/ui_canvas.tscn")
const MILO_SCENE: PackedScene = preload("res://scenes/milo.tscn")
const OVERWORLD: PackedScene = preload("res://scenes/overworld.tscn")

const DIALOGUE_SCREEN: PackedScene = preload("res://scenes/dialog_screen.tscn")
const NPC_BASE_SCENE: PackedScene = preload("res://scenes/npc_base.tscn")

# --- Core References ---
var main_node: Node2D = null
var milo: CharacterBody2D = null
var overworld: Node2D = null
var global_gui: CanvasLayer = null
var dialogue_hud: Control = null

func _ready() -> void:
	print("GameManager: System initialized.")

# Triggered by main.gd to boot the game structure
func start_game(node: Node2D) -> void:
	main_node = node
	load_overworld()
	_initialize_global_gui()	
	load_dialog_hud()

func _initialize_global_gui() -> void:
	print("GameManager: Initializing Global GUI...")
	if main_node:
		global_gui = UI_SCENE.instantiate()
		main_node.add_child(global_gui)

# Instantiates the level and hooks it up to the main node
func load_overworld() -> void:
	overworld = OVERWORLD.instantiate() as Node2D
	main_node.add_child(overworld)
	
	# Safely fetches the spawn marker from the newly loaded level
	var spawn_node = overworld.get_node_or_null("spawn")
	if spawn_node:
		spawn_milo(spawn_node.global_position)

		# NPC Test
		var npc_pos_1 = Vector2(1800, 960)
		spawn_npc_at_position(npc_pos_1)
	else:
		push_error("GameManager: 'spawn' node not found! Spawning at Vector2.ZERO.")
		spawn_milo(Vector2.ZERO)

# Spawns Milo inside the level at the designated position
func spawn_milo(global_pos: Vector2) -> void:
	if not overworld:
		print("GameManager: Cannot spawn Milo because overworld is not loaded.")
		return

	milo = MILO_SCENE.instantiate() as CharacterBody2D
	milo.global_position = global_pos
	overworld.add_child(milo)
	print("GameManager: Milo spawned successfully at: ", global_pos)

func spawn_npc_at_position(map_position: Vector2) -> void:
	if not overworld:
		return
		
	if not NPC_BASE_SCENE:
		return

	var npc_instance = NPC_BASE_SCENE.instantiate() as Area2D
	npc_instance.global_position = map_position
	
	overworld.add_child(npc_instance)
	print("GameManager: Loads NPC in the position Vector2: ", map_position)

func load_dialog_hud() -> void:
	if global_gui:
		dialogue_hud = DIALOGUE_SCREEN.instantiate() as Control
		dialogue_hud.position = Vector2(240,250)
		global_gui.add_child(dialogue_hud)

func start_dialogue(lines: Array[String]) -> void:	
	print("[Game Manager] Start dialog...")
	dialogue_hud.start_dialogue(lines)

