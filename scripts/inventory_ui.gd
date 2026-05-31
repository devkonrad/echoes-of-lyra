extends Control

# --- Node References ---
@onready var item_list: ItemList = $MarginContainer/Panel/VBoxContainer/ItemList
@onready var description_label: Label = $MarginContainer/Panel/VBoxContainer/DescriptionLabel

func _ready() -> void:
	# Start hidden by default
	hide()
	# Connect list selection signal to update the description
	item_list.item_selected.connect(_on_item_selected)

# Toggles the visibility of the inventory window and handles game pause
func toggle() -> void:
	if visible:
		hide()
		get_tree().paused = false # Unpauses the overworld when closing
	else:
		show()
		_update_inventory_display()
		get_tree().paused = true # Pauses Milo and the world when browsing items

# Clears and rebuilds the visual list based on GameManager data in real-time
func _update_inventory_display() -> void:
	item_list.clear()
	description_label.text = "Select an item..."
	
	# Fetching directly from the source to prevent frozen or null state references
	if GameManager.inventory.is_empty():
		item_list.add_item("Empty...")
		return
		
	for item in GameManager.inventory:
		if item:
			# Adds the item name and its texture icon if it exists
			var index = item_list.add_item(item.item_name, item.texture)
			# Store the item reference inside the metadata slot of the list row
			item_list.set_item_metadata(index, item)

# Triggered when the player clicks or selects an item in the list
func _on_item_selected(index: int) -> void:
	# Retrieve the ItemData resource stored in this row's metadata
	var item = item_list.get_item_metadata(index) as ItemData
	if item:
		description_label.text = item.description
	else:
		description_label.text = ""
