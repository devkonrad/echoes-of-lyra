extends Node

# Stores the runtime catalog of all items loaded from JSON
# Key: String (item_id) -> Value: ItemData
var item_catalog: Dictionary = {}

const DATABASE_PATH: String = "res://data/items_database.json"

func _ready() -> void:
	_load_item_database()

# Reads the JSON file and constructs the ItemData objects in memory
func _load_item_database() -> void:
	if not FileAccess.file_exists(DATABASE_PATH):
		push_error("[ItemManager] Critical Error: Database file not found at " + DATABASE_PATH)
		return
		
	var file = FileAccess.open(DATABASE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("[ItemManager] JSON Parse Error: " + json.get_error_message())
		return
		
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[ItemManager] Invalid JSON structure. Root must be a Dictionary.")
		return
		
	# Rebuild the catalog dynamically
	item_catalog.clear()
	for item_id in data:
		var item_data_dict = data[item_id]
		var new_item = _create_item_data_from_dict(item_id, item_data_dict)
		item_catalog[item_id] = new_item
		
	print("[ItemManager] Database successfully loaded! Total items: ", item_catalog.size())

# Helper function to parse raw dictionary data into typed ItemData
func _create_item_data_from_dict(item_id: String, dict: Dictionary) -> ItemData:
	var item = ItemData.new()
	item.id = item_id
	item.item_name = dict.get("name", "Unknown Item")
	item.description = dict.get("description", "")
	
	# Safe texture loading
	var tex_path = dict.get("texture_path", "res://icon.svg")
	if ResourceLoader.exists(tex_path):
		item.texture = load(tex_path) as Texture2D
	
	# Parse Enums safely from Strings
	var type_str = dict.get("item_type", "CONSUMABLE")
	if type_str in ItemData.ItemType:
		item.item_type = ItemData.ItemType[type_str]
		
	var effect_str = dict.get("effect_type", "NONE")
	if effect_str in ItemData.EffectType:
		item.effect_type = ItemData.EffectType[effect_str]
		
	item.effect_value = int(dict.get("effect_value", 0))
	
	return item

# Public method to fetch a clean duplicate of any item from the catalog
func get_item(item_id: String) -> ItemData:
	if item_catalog.has(item_id):
		# Return a duplicate so runtime instances don't override the master database template
		return item_catalog[item_id].duplicate() as ItemData
		
	push_warning("[ItemManager] Item ID not found in catalog: " + item_id)
	return null

# --- Item Usage and Effect Execution ---

## Main entry point to apply an item's logic to the game state.
## Returns true if the effect was executed successfully, false if usage was rejected.
func apply_item_effect(item: ItemData) -> bool:
	if not item:
		return false
		
	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			return _execute_consumable_effect(item)
		ItemData.ItemType.EQUIPMENT:
			return _toggle_equipment(item)
		ItemData.ItemType.QUEST:
			print("[ItemManager] Quest item '", item.item_name, "' cannot be used directly from the menu.")
			return false
			
	return false

# Handles immediate, one-time effects from potions and supplies
func _execute_consumable_effect(item: ItemData) -> bool:
	match item.effect_type:
		ItemData.EffectType.HEAL:
			# Safety check: Reject usage if player is already at full health in Overworld
			if PlayerStateManager.current_health >= PlayerStateManager.max_health:
				print("[ItemManager] Milo's overworld health is already full! Item usage cancelled.")
				return false
				
			# Apply the healing safely using the state manager's API
			PlayerStateManager.heal_overworld(item.effect_value)
			print("[ItemManager] Milo consumed ", item.item_name, ". Healed by: ", item.effect_value)
			return true
			
		ItemData.EffectType.NONE:
			print("[ItemManager] ", item.item_name, " has no applicable consumable effect.")
			return true # Still consumed safely even if it's just flavor text
			
		_:
			push_warning("[ItemManager] Unhandled consumable effect type: " + str(item.effect_type))
			return false

# Handles toggling equipment stats on and off (Weapons, Armor, Accessories)
func _toggle_equipment(item: ItemData) -> bool:
	# Check if the item is already equipped (we will store this flag inside individual item copies)
	# By convention, let's create a dynamic metadata dictionary if it doesn't exist
	if not item.has_meta("is_equipped"):
		item.set_meta("is_equipped", false)
		
	var is_currently_equipped: bool = item.get_meta("is_equipped")
	
	if is_currently_equipped:
		# --- DESEQUIPAR ---
		item.set_meta("is_equipped", false)
		_apply_stat_modifier(item.effect_type, -item.effect_value) # Subtract the bonus
		print("[ItemManager] Unequipped: ", item.item_name, ". Buff removed.")
	else:
		# --- EQUIPAR ---
		# NOTE: Future improvement can clear previous equipment items from the same slot here.
		item.set_meta("is_equipped", true)
		_apply_stat_modifier(item.effect_type, item.effect_value) # Add the bonus
		print("[ItemManager] Equipped: ", item.item_name, ". Buff applied: +", item.effect_value)
		
	return true

# Helper function to inject modifier numbers into PlayerStateManager variables
func _apply_stat_modifier(effect: ItemData.EffectType, modifier_value: int) -> void:
	match effect:
		ItemData.EffectType.EQUIP_ATK:
			# Safely checking if the player state manager tracking variable exists
			if "attack_power" in PlayerStateManager:
				PlayerStateManager.attack_power += modifier_value
				print("[ItemManager] Milo's Attack Power modified to: ", PlayerStateManager.attack_power)
			else:
				# Fallback warning if your tracker uses a different variable name
				push_warning("[ItemManager] 'attack_power' property not found in PlayerStateManager.")
		_:
			push_warning("[ItemManager] Unhandled equipment stat modifier: " + str(effect))
