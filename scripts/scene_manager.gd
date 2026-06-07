## Global Autoload that manages scene transitions, memory cleanup, and state persistence.
##
## Handles standard overworld map swaps, dynamic camera binding, player position
## persistence across maps, and dynamic data injection for combat screens.
extends CanvasLayer

# --- Node References ---

@onready var animation: AnimationPlayer = $TransitionAnimation
@onready var transition_color: ColorRect = $TransitionColor

# --- Path Configurations ---

## Base directory directory path for game scenes.
var scene_dir_path: String = "res://scenes/"

# --- Position & Tracking State ---

## Temporarily holds the target spawn coordinates for the player entity.
var hero_spawn_position: Vector2 = Vector2.ZERO

## Stores the last known coordinates of the player per map. Key: scene_path (String), Value: global_position (Vector2).
var hero_last_positions: Dictionary = {}

## Historical tracker for the last active scene path. Used for returning from battles.
var previous_scene_path: String = ""

## Accurate pointer tracker to the currently running scene file path.
var current_scene_path: String = ""

## Direct reference to the active root scene node instantiated into the main tree node.
var active_scene_node: Node = null


# --- Core Loading Methods ---

## Instantiates a scene by its name string, handles camera binding, and injects optional battle payload data.
## Returns a [Variant] to support asynchronous execution using the 'await' keyword.
func load_scene(scene_name: String, is_battle: bool = false, encounter_data: BattleEncounter = null) -> Variant:
	if scene_name.is_empty():
		print("[SceneManager] Error: scene_name is empty!")
		return null
	
	var full_path: String = scene_dir_path + scene_name + ".tscn"
	var packed_scene: PackedScene = load(full_path) as PackedScene

	if packed_scene:
		transition_color.visible = true

		# --- Conditional Overworld Position Calculations ---
		if not is_battle:
			var temp_scene: Node = packed_scene.instantiate()
			var spawn_node: Marker2D = temp_scene.get_node_or_null("hero_spawn") as Marker2D
			var fallback_pos: Vector2 = spawn_node.position if spawn_node else Vector2.ZERO

			if not spawn_node:
				print("[SceneManager] Warn: 'hero_spawn' not found in scene: ", scene_name)
				temp_scene.queue_free()
				return null

			# Pull saved positioning data if it exists, otherwise use marker coordinates
			hero_spawn_position = _get_hero_position(full_path, fallback_pos)

			# Safely drop memory allocations from the calculation probe
			temp_scene.queue_free()

		# Lock core scene variables
		current_scene_path = full_path
		active_scene_node = packed_scene.instantiate()
		
		# --- Node Tree Integration ---
		# CRITICAL: We add the scene to the main tree FIRST so its lifecycle initialization triggers.
		GameManager.main_node.add_child(active_scene_node)

		# --- Dynamic Camera System Integration ---
		if is_instance_valid(active_scene_node):
			var current_camera: Camera2D = active_scene_node.get_node_or_null("Camera") as Camera2D
			if current_camera:
				GameManager.setCurrentCamera(current_camera)

		# --- Battle Sub-System Data Injection ---
		if is_battle and encounter_data:
			# Safety Guard: Await the node to be completely ready in the hierarchy 
			# to prevent race conditions with internal @onready variables.
			if not active_scene_node.is_node_ready():
				await active_scene_node.ready
			
			if active_scene_node.has_method("init_battle"):
				active_scene_node.init_battle(encounter_data)
			else:
				print("[SceneManager] Warn: Target battle scene has no 'init_battle' API method!")

		# Lock initial overworld viewports directly to character spawn points
		if not is_battle and is_instance_valid(GameManager.current_camera):
			GameManager.current_camera.global_position = hero_spawn_position

		# Fade transitions processing
		animation.play("fade_in")
		await animation.animation_finished

		# Await framework visual synchronization steps
		await get_tree().process_frame

		return active_scene_node

	print("[SceneManager] Error: Failed to load packed scene at: ", full_path)
	return null


## Fades out the viewport and safely frees the active scene and actor assets from memory.
func unload_scene() -> void:
	if current_scene_path.is_empty():
		print("[SceneManager] Error: current_scene_path is already empty!")
		return

	transition_color.visible = true
	animation.play("fade_out")
	await animation.animation_finished

	previous_scene_path = current_scene_path

	# Wipe instances and prevent memory leaks
	if is_instance_valid(active_scene_node):
		if is_instance_valid(GameManager.milo):
			GameManager.milo.queue_free()
			GameManager.milo = null
		active_scene_node.queue_free()
	
	# Reset state fields
	hero_spawn_position = Vector2.ZERO
	current_scene_path = ""


# --- Map & Mode Flow API ---

## Manages high-level overworld scene swaps: updates position caches, unloads, loads, and spawns the actor.
func change_to_scene(scene_name: String) -> void:
	_set_hero_position(current_scene_path, GameManager.milo)

	# Disable battle bar
	if GameManager.global_gui.battle_ui_menu:
		GameManager.global_gui.battle_ui_menu.visible = false

	await unload_scene()
	await load_scene(scene_name)
	
	GameManager.spawn_milo(hero_spawn_position) 


## Reads tracking properties to return the runtime back to the previous scene index.
func go_back() -> void:
	if previous_scene_path.is_empty():
		print("[SceneManager] Error: No previous scene path saved in history!")
		return

	var target_scene_name: String = previous_scene_path.get_file().get_basename()
	print("[SceneManager] Returning to previous scene: ", target_scene_name)
	
	await change_to_scene(target_scene_name)


## Dedicated battle entry sequencer. Persists positions and passes combat configuration payloads.
func change_to_battle(scene_name: String, encounter_data: BattleEncounter) -> void:
	_set_hero_position(current_scene_path, GameManager.milo)

	await unload_scene()

	# Enable battle bar
	if GameManager.global_gui.battle_ui_menu:
		GameManager.global_gui.battle_ui_menu.visible = true

	# Execute dynamic combat injection loops
	await load_scene(scene_name, true, encounter_data)

	# NOTE: The GameManager.spawn_milo() function should NOT be called here.
	# The battle room itself will manage the location of Milo and the monsters!


# --- Private Helper Methods ---

## Caches the player's last known position coordinates mapping to the unique scene path key.
func _set_hero_position(scene_path: String, hero: CharacterBody2D) -> void:
	if scene_path.is_empty() or not is_instance_valid(hero):
		return

	hero_last_positions[scene_path] = hero.global_position
	print("[SceneManager] Position stored for: ", scene_path, " -> ", hero.global_position)


## Fetches cached player positions or drops down cleanly to localized scene layouts.
func _get_hero_position(scene_path: String, fallback_position: Vector2) -> Vector2:
	if hero_last_positions.has(scene_path):
		print("[SceneManager] Found saved position for: ", scene_path)
		return hero_last_positions[scene_path]
	
	print("[SceneManager] No saved position. Using fallback marker position.")
	return fallback_position
