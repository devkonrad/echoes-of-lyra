extends Node

# --- Inventory System ---
var inventory: Array[ItemData] = []

func _ready() -> void:
	print("InventoryManager: System initialized.")

func add_item(item: ItemData) -> void:
	if not item:
		print("[InventoryManager] Error: Trying to add a null item!")
		return
		
	inventory.append(item)
