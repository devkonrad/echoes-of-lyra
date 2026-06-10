extends Control

# --- Node References ---
@onready var tab_container: TabContainer = $Panel/VBoxContainer/TabContainer
@onready var consumables_list: ItemList = $Panel/VBoxContainer/TabContainer/Items
@onready var equipments_list: ItemList = $Panel/VBoxContainer/TabContainer/Equips
@onready var quest_list: ItemList = $Panel/VBoxContainer/TabContainer/Quest
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel

func _ready() -> void:
	hide()
	
	# Connect selection and activation signals for all three lists
	for list in [consumables_list, equipments_list, quest_list]:
		list.item_selected.connect(_on_item_selected.bind(list))
		list.item_activated.connect(_on_item_activated.bind(list))
		
	# Clear description when player changes tabs
	tab_container.tab_changed.connect(_on_tab_changed)

func toggle() -> void:
	if visible:
		hide()
		get_tree().paused = false
	else:
		show()
		_update_inventory_display()
		get_tree().paused = true

# Rebuilds all three category lists dynamically
func _update_inventory_display() -> void:
	# Clear previous data from all slots
	consumables_list.clear()
	equipments_list.clear()
	quest_list.clear()
	description_label.text = "Select an item..."
	
	if InventoryManager.inventory.is_empty():
		return
		
	# Route each item into its respective tab list based on its type
	for item in InventoryManager.inventory:
		if not item:
			continue
			
		var target_list: ItemList = null
		var display_name: String = item.item_name
		
		match item.item_type:
			ItemData.ItemType.CONSUMABLE:
				target_list = consumables_list
			ItemData.ItemType.EQUIPMENT:
				target_list = equipments_list
				# Apply the visual equipment tag
				if item.get_meta("is_equipped", false):
					display_name = "[E] " + display_name
			ItemData.ItemType.QUEST:
				target_list = quest_list
				
		if target_list:
			var index = target_list.add_item(display_name, item.texture)
			# Store the original inventory context reference directly in the specific list row
			target_list.set_item_metadata(index, item)

# Triggered when an item is highlighted in any active list
func _on_item_selected(index: int, active_list: ItemList) -> void:
	var item = active_list.get_item_metadata(index) as ItemData
	if item:
		description_label.text = item.description

# Triggered when Enter/Double-click is pressed on any list
func _on_item_activated(index: int, active_list: ItemList) -> void:
	var item = active_list.get_item_metadata(index) as ItemData
	if not item:
		return
		
	var success: bool = ItemManager.apply_item_effect(item)
	
	if success:
		if item.item_type == ItemData.ItemType.CONSUMABLE:
			# Find and erase the specific object reference from backend storage
			InventoryManager.inventory.erase(item)
			
		# Refresh everything to update icons and lists
		_update_inventory_display()

func _on_tab_changed(_tab_index: int) -> void:
	description_label.text = "Select an item..."
