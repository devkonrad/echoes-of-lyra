extends CanvasLayer

@onready var inventory_ui = $InventoryUI

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.toggle()
