extends Node

# --- Preloaded Scenes (Assets) ---
const UI_SCENE: PackedScene = preload("res://scenes/ui_canvas.tscn")
const MILO_SCENE: PackedScene = preload("res://scenes/milo.tscn")
const NPC_BASE_SCENE: PackedScene = preload("res://scenes/npc_base.tscn")

# GUI
var global_gui: CanvasLayer = null

# Level parameters
var main_node: Node2D = null

# Hero parameters
var milo: CharacterBody2D = null
var milo_portrait: Texture2D = null

# Camera
var current_camera: Camera2D = null

func _ready() -> void:
	print("GameManager: System initialized.")

func setCurrentCamera(camera: Camera2D):
	current_camera = camera

func start_game(node: Node2D) -> void:
	print("[GameManager] Starting the game...")

	# Level load
	main_node = node
	await SceneManager.load_scene("overworld")

	# Inicializa a interface gráfica global
	_initialize_global_gui()

	# Hero spawn (just works after load the overworld)
	spawn_milo(SceneManager.hero_spawn_position)

func spawn_milo(global_pos: Vector2) -> void:
	if not SceneManager.current_scene_path:
		print("GameManager: Cannot spawn Milo because current_scene_path is empty.")
		return

	milo = MILO_SCENE.instantiate() as CharacterBody2D
	milo.global_position = global_pos

	if "milo_portrait" in milo:
		milo.milo_portrait = load("res://avatar/milo.png") as Texture2D
		milo_portrait = milo.milo_portrait

	get_tree().current_scene.add_child(milo)
	print("GameManager: Milo spawned successfully at: ", global_pos)

# SIMPLE NPC - FOR DEBUG PURPOSES
func spawn_npc_at_position(map_position: Vector2) -> void:
	if not NPC_BASE_SCENE:
		return

	var npc_instance = NPC_BASE_SCENE.instantiate() as Area2D
	npc_instance.global_position = map_position
	
	get_tree().current_scene.add_child(npc_instance)
	print("GameManager: Loads NPC in the position Vector2: ", map_position)

func _spawn_npc_for_debug() -> void:
	var npc_pos_1 = Vector2(1750, 960)
	spawn_npc_at_position(npc_pos_1)

func _initialize_global_gui() -> void:
	print("GameManager: Initializing Global GUI...")
	"""
	if main_node:
		global_gui = UI_SCENE.instantiate()
		main_node.add_child(global_gui)
		
		# Pedimos ao DialogManager para carregar o HUD dele usando a nossa GUI recém-criada
		DialogManager.load_dialog_hud(global_gui)
	"""
