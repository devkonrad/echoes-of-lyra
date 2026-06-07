## Handles the visual bounce animation of a dropped item and rewards it to the player inventory.
extends Control
class_name VictoryDrop

@onready var item_sprite: Sprite2D = $ItemSprite

## Strongly typed to match your inventory data class configuration
var reward_item: ItemData

## Starts the falling and bouncing animation in the middle of the screen.
func launch_drop(item_to_grant: ItemData) -> void:
	reward_item = item_to_grant
	
	if reward_item and reward_item.texture:
		item_sprite.texture = reward_item.texture
		item_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
	var center_position: Vector2 = get_viewport_rect().size / 2.0
	item_sprite.global_position = center_position + Vector2(0, -200)
	item_sprite.scale = Vector2(0.0, 0.0)
	item_sprite.modulate.a = 0.0
	
	# Tell the tween to run everything inside a block SIMULTANEOUSLY by default
	var tween: Tween = create_tween().set_parallel(true)
	
	# --- PHASE 1: Fall down, scale up, and fade in at the same time ---
	tween.tween_property(item_sprite, "global_position:y", center_position.y, 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(item_sprite, "scale", Vector2(1.2, 1.2), 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(item_sprite, "modulate:a", 1.0, 0.2)
		
	# --- PHASE 2: Bounces (We use .chain() to wait for Phase 1 to finish, and .set_parallel(false) for sequential jumps) ---
	var bounce_chain = tween.chain().set_parallel(false)
	
	# First Bounce
	bounce_chain.tween_property(item_sprite, "global_position:y", center_position.y - 40, 0.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	bounce_chain.tween_property(item_sprite, "global_position:y", center_position.y, 0.15)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
		
	# Second Bounce
	bounce_chain.tween_property(item_sprite, "global_position:y", center_position.y - 15, 0.15)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	bounce_chain.tween_property(item_sprite, "global_position:y", center_position.y, 0.12)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
		
	# Settle down scale
	bounce_chain.tween_property(item_sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Wait and trigger collection flow
	bounce_chain.tween_interval(1.5)
	bounce_chain.tween_callback(_collect_and_announce)


## Adds the item, triggers the screen announcement, and transitions to the inventory view.
func _collect_and_announce() -> void:
	if not reward_item:
		queue_free()
		return
		
	# 1. Add the item data to the global Inventory Manager
	InventoryManager.add_item(reward_item)
	print("[Reward] Item collected and pushed to inventory: ", reward_item.item_name)
	
	# 2. Dynamically search for the battle UI node in the parent layer
	var ui_canvas = get_parent()
	var battle_ui: Node = null
	
	if ui_canvas:
		# Search check: looking for the node regardless of case variations
		for child in ui_canvas.get_children():
			if child.name.to_lower() == "battleuimenu" or child.name.to_lower() == "battle_ui_menu":
				battle_ui = child
				break
				
	# 3. Fire the announcement if found, otherwise skip straight to inventory
	if battle_ui and battle_ui.has_method("announce_event"):
		var msg: String = "You got the " + reward_item.item_name + "!"
		
		# Pass the finalization window toggle as the completion hook
		battle_ui.announce_event(msg, _final_victory_flow)
	else:
		print("[Reward] Warning: BattleUIMenu node or announce_event method not found. Skipping to inventory.")
		_final_victory_flow()
	
	# Clean up visibility before fading out the node layout entirely
	item_sprite.hide()


## Unlocks input hud hooks and toggles the inventory interface presentation state.
func _final_victory_flow() -> void:
	var ui_canvas = get_parent()
	if ui_canvas:
		# A) UNLOCK HUD BUTTON: Enable and reveal the inventory navigation toggle if present
		if ui_canvas.has_node("InventoryButton"):
			ui_canvas.get_node("InventoryButton").disabled = false
			ui_canvas.get_node("InventoryButton").show()
		
		# B) SHOW INVENTORY WINDOW: Invoke the toggle system to display the item lists
		if ui_canvas.has_node("InventoryUI"):
			ui_canvas.get_node("InventoryUI").toggle()
			
	queue_free()
