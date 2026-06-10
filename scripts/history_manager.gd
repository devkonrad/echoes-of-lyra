## Manages global game progression flags, external dialogue JSON routing, and event sequencing.
extends Node

## Holds the raw parsed data from the current active dialogue file
var current_dialogue_data: Dictionary = {}

## Pointer to track the active node within the dialogue tree graph layout
var current_node_id: String = ""

## Tracks if an item reward was granted during the conversation session
var should_open_inventory: bool = false

## Persistent registry storage tracking completed game story choices/flags
var story_flags: Dictionary = {}

func _ready() -> void:
	print("HistoryManager: System initialized.")

## Loads an external JSON file from disk into the runtime memory cache.
func load_dialogue_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		print("[HistoryManager] Error: Dialogue file not found at: ", file_path)
		return false
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		current_dialogue_data = json.data
		current_node_id = current_dialogue_data.get("start_node_id", "")
		# Reset the session tracking flag whenever a new conversation boots up
		should_open_inventory = false
		print("[HistoryManager] Successfully loaded dialogue: ", file_path)
		return true
	else:
		print("[HistoryManager] Error parsing JSON: ", json.get_error_message())
		return false

## Returns the dictionary data structure corresponding to the active node cursor.
func get_current_node() -> Dictionary:
	var nodes = current_dialogue_data.get("nodes", {})
	return nodes.get(current_node_id, {})

## Advances the dialogue graph pointer based on the selected choice branch row index.
func advance_dialogue_by_choice(choice_index: int) -> void:
	var current_node = get_current_node()
	var choices = current_node.get("choices", [])
	
	if choice_index < choices.size():
		var chosen_branch = choices[choice_index]
		current_node_id = chosen_branch.get("next_node_id", "end_nodes")
		_process_node_side_effects()
	else:
		current_node_id = "end_nodes"

## Checks the node data structure for progression world flags and story metadata.
func _process_node_side_effects() -> void:
	var current_node = get_current_node()
	
	# NOTE: Future narrative tracking logic (like setting story_flags["defeated_boss"] = true)
	# based on the node's choice outcomes will be processed here safely.
	pass
