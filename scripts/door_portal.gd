## Triggers map switches and battle transitions when the player interacts with its collision area.
##
## Handles standard bidirectional overworld level streaming, traditional back-navigation,
## and dynamic runtime resource bundling for combat triggers.
extends Area2D
class_name DoorPortal

# --- Inspector Configurations ---

@export_group("Target Destination")
## If true, instructs the SceneManager to pop the history stack and return to the previous location.
@export var go_back: bool = false

## Name of the target scene file (excluding directory path and extensions) to stream in.
@export var to_scene_name: String = ""

@export_group("Battle Configuration")
## Toggles whether this gateway loads an overworld map or kicks off the turn-based combat suite.
@export var is_battle: bool = false

## Filename of the target BattleEncounter resource file (e.g., 'battle_with_slime_01.tres').
@export var battle_resource_filename: String = ""

# --- Runtime Tracking State ---

## Flags whether a valid character entity is currently overlapping the interaction trigger shape.
var is_player_overlapping: bool = false


# --- Lifecycle Hooks ---

func _ready() -> void:
	# Wire up interaction detection listeners safely via code
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Listens to unhandled inputs globally, executing operations if the contextual overlap conditions are met.
func _input(event: InputEvent) -> void:
	if is_player_overlapping and event.is_action_pressed("ui_interact"):
		_trigger_scene_transition()


# --- Signal Callbacks ---

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_overlapping = true
		if is_battle:
			print("[Portal] Danger! Press Action Button to start the battle!")
		else:
			print("[Portal] Milo is at the door. Press Action Button to enter!")


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_overlapping = false


# --- Core Transition Orchestration ---

## Evaluates targeted parameters and delegates tasks over to the global SceneManager system.
func _trigger_scene_transition() -> void:
	# Case 1: Pop scene history stack backwards
	if go_back:
		print("[Portal] Requesting return to previous scene...")
		SceneManager.go_back()
		return

	# Case 2: Instantiating combat encounters with dynamic payloads
	if is_battle:
		if battle_resource_filename.is_empty():
			print("[Portal] Error: 'battle_resource_filename' configuration missing on Inspector!")
			return

		var resource_path: String = "res://resources/" + battle_resource_filename
		var fight_data: BattleEncounter = load(resource_path) as BattleEncounter

		if fight_data:
			await SceneManager.change_to_battle(to_scene_name, fight_data)
		else:
			print("[Portal] Error: Could not find or load battle resource data at: ", resource_path)
		return

	# Case 3: Standard progressive map transitions
	if not to_scene_name.is_empty():
		await SceneManager.change_to_scene(to_scene_name)
	else:
		print("[Portal] Warning: Interaction skipped. 'to_scene_name' parameter is empty.")
