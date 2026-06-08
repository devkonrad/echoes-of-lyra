## Manages global game progression flags, external dialogue JSON routing, and event sequencing.
extends Node

## Holds the raw parsed data from the current active dialogue file
var current_dialogue_data: Dictionary = {}

## Pointer to track the active node within the dialogue tree graph layout
var current_node_id: String = ""

## Tracks if an item reward was granted during the conversation session
var should_open_inventory: bool = false

## THE NEW FEATURE: Persistent registry storage tracking completed game story choices/flags
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

## Checks the node data structure for item drops or progression world flags.
func _process_node_side_effects() -> void:
	var current_node = get_current_node()
	
	# Intercept and process unique conditional reward configurations
	if current_node.has("reward_item_id"):
		var item_id = current_node.get("reward_item_id")
		
		# Build a unique progressive identifier anchor name based on this file node structure
		var unique_reward_flag = current_node_id + "_reward_claimed"
		
		# THE SAFETY LOCK: Only execute granting pipeline logic if the flag record turns up empty
		if not story_flags.get(unique_reward_flag, false):
			_grant_item_to_milo(item_id)
			story_flags[unique_reward_flag] = true
		else:
			print("[HistoryManager] Reward skip: Player has already claimed the item link: ", unique_reward_flag)

## Resolves item rewards by grabbing the registered ItemData resource files.
func _grant_item_to_milo(item_id: String) -> void:
	var resource_path = "res://resources/items/" + item_id + ".tres"
	
	if ResourceLoader.exists(resource_path):
		var item_res = load(resource_path) as ItemData
		if item_res:
			InventoryManager.add_item(item_res)
			# Raise the trigger flag to automatically present the inventory UI upon dialogue close
			should_open_inventory = true
			print("[HistoryManager] Dialogue triggered reward granted: ", item_res.item_name)
	else:
		print("[HistoryManager] Error: Item resource file could not be found at: ", resource_path)
