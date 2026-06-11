extends Node

# --- Inventory System ---
var inventory: Array[ItemData] = []

func _ready() -> void:
	print("InventoryManager: System initialized.")


## Scans the inventory backend to check if Milo owns a specific item ID.
## Returns the ItemData instance if found, or null if it doesn't exist.
func get_item(item_id: String) -> ItemData:
	for owned_item in inventory:
		if owned_item.id == item_id:
			return owned_item
	return null


## Convenience helper to check ownership quickly via boolean query.
func has_item(item_id: String) -> bool:
	return get_item(item_id) != null


## High-level API to fetch and add an item directly using its JSON catalog ID string.
## Returns true if successfully added, or false if blocked or not found.
func add_item_by_id(item_id: String) -> bool:
	var target_id: String = item_id.strip_edges()
	if target_id == "":
		print("[InventoryManager] Error: Cannot add item with an empty ID string.")
		return false
		
	# Fetch the hydrated ItemData resource directly from the master catalog
	var new_item: ItemData = ItemManager.get_item(target_id)
	
	if not new_item:
		print("[InventoryManager] Error: Item ID '", target_id, "' could not be resolved by ItemManager.")
		return false
		
	# Forward the valid item resource to our standard safe addition pipeline
	return add_item(new_item)


## Attempts to add an item to Milo's inventory backend.
## Delegates uniqueness validation checks over to the query system.
func add_item(new_item: ItemData) -> bool:
	if not new_item:
		print("[InventoryManager] Error: Trying to add a null item!")
		return false
		
	# --- SEPARATED RESPONSIBILITY CHECK ---
	# If the item is unique and we can already find its ID in the inventory, block it!
	if new_item.is_unique and has_item(new_item.id):
		print("[InventoryManager] Rejection: Milo already possesses unique item -> ", new_item.id)
		return false
				
	# If it's safe to proceed, append the dynamic resource straight into the array
	inventory.append(new_item)
	print("[InventoryManager] Success: Added item -> ", new_item.item_name)
	return true
