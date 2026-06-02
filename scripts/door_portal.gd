extends Area2D

# --- Inspector Configuration ---
@export_group("Target Destination")
@export var go_back: bool = false
@export var to_scene_name: String = "" # Mudado de null para "" já que String não aceita null nativamente no GDScript

# --- Runtime Data ---
var is_player_overlapping: bool = false

func _ready() -> void:
	# Connect overlap signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	# Checks if Milo is standing on the portal and pressed the action button
	if is_player_overlapping and event.is_action_pressed("ui_interact"):
		_trigger_scene_transition()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_overlapping = true
		print("[Portal] Milo is at the door. Press Action Button to enter!")

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_overlapping = false

func _trigger_scene_transition() -> void:
	if go_back:
		print("[Portal] Requesting return to previous scene...")
		SceneManager.go_back()

		return

	await SceneManager.change_to_scene(to_scene_name)
