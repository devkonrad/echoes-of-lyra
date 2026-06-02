extends CanvasLayer

@onready var animation: AnimationPlayer = $TransitionAnimation
@onready var transtition_color: ColorRect = $TransitionColor 

var scene_dir_path: String = "res://scenes/"

# Hero Spawn
var hero_spawn_position: Vector2 = Vector2.ZERO

# Position control by maps
var hero_last_positions: Dictionary = {}

# Scene control
var previous_scene_path: String = ""
var current_scene_path: String = ""

# Track the actual instantiated node inside main_node
var active_scene_node: Node = null

# Changed return type to Variant to support async 'await' behavior in Godot 4
func load_scene(scene_name: String) -> Variant:
	if not scene_name:
		print("[load_scene] Error: scene_name is empty!")
		return null
	
	var full_path: String = scene_dir_path + scene_name + ".tscn"
	var packed_scene: PackedScene = load(full_path)

	if packed_scene:
		transtition_color.visible = true

		var temp_scene: Node = packed_scene.instantiate()
		var spawn_node: Marker2D = temp_scene.get_node_or_null("hero_spawn") as Marker2D
		var fallback_pos: Vector2 = spawn_node.position if spawn_node else Vector2.ZERO
		
		if not spawn_node:
			print("[load_scene] Warn: 'hero_spawn' not found ", scene_name)
			temp_scene.queue_free()
			return null

		# Try to load hero position
		hero_spawn_position = _get_hero_position(full_path, fallback_pos)

		# Free memory from temporary instance
		temp_scene.queue_free()

		# Save current tracking
		current_scene_path = full_path

		# Change scene
		active_scene_node = packed_scene.instantiate()
		
		GameManager.main_node.add_child(
			active_scene_node
		)

		# Fade effect
		animation.play("fade_in")
		await animation.animation_finished

		# Wait for the engine to completely switch the scene at the end of the frame
		await get_tree().process_frame

		return active_scene_node

	return null


func unload_scene() -> void:
	if current_scene_path == "":
		print("[unload_scene] Error: current_scene_path is already empty!")
		return

	# Fixed to fade_out so the screen turns black before clearing nodes from memory
	transtition_color.visible = true
	animation.play("fade_out")
	await animation.animation_finished

	previous_scene_path = current_scene_path

	# Clean scene from memory
	if is_instance_valid(active_scene_node):
		GameManager.milo.queue_free()
		GameManager.milo = null
		active_scene_node.queue_free()
	
	# Reset variables
	hero_spawn_position = Vector2.ZERO
	current_scene_path = ""


# Change from an scene to another
func change_to_scene(scene_name: String) -> void:
	_set_hero_position(
		current_scene_path,
		GameManager.milo
	)

	await unload_scene()
	await load_scene(scene_name)
	
	GameManager.spawn_milo(hero_spawn_position)
	

# Change to previous scene
func go_back() -> void:
	if previous_scene_path == "":
		print("[go_back] Error: No previous scene path saved in history!")
		return

	var target_scene_name: String = previous_scene_path.get_file().get_basename()
	
	print("[go_back] Returning to previous scene: ", target_scene_name)
	await change_to_scene(target_scene_name)

# local methods
func _set_hero_position(scene_path: String, hero: CharacterBody2D) -> void:
	if scene_path == "" or not is_instance_valid(hero):
		return

	hero_last_positions[scene_path] = hero.global_position
	print("[_set_hero_position] Position stored for: ", scene_path, " -> ", hero.global_position)


func _get_hero_position(scene_path: String, fallback_position: Vector2) -> Vector2:
	if hero_last_positions.has(scene_path):
		print("[_get_hero_position] Found saved position for: ", scene_path)
		return hero_last_positions[scene_path]
	
	print("[_get_hero_position] No saved position. Using fallback marker position.")
	return fallback_position
	