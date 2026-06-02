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
	print("[InventoryManager] Item added to inventory: ", item.item_name)
	# No futuro, podemos emitir um sinal aqui para atualizar a UI:
	# item_added.emit(item)
