extends Area2D

# --- Individual Item Overrides (Inspector Configuration) ---
@export_group("Custom Item Settings")
@export var item_name_override: String = ""
@export_multiline var description_override: String = ""
@export var texture_override: Texture2D
@export var is_consumable_override: bool = false

# --- Sprite Sheet Cutting Properties ---
@export_group("Sprite Sheet Atlas Settings")
@export var use_atlas_cutting: bool = false
@export var sprite_sheet: Texture2D
@export var region_rect: Rect2
@export var filter_nearest: bool = true

# --- Optional Global Resource ---
@export_group("Global Resource")
@export var item_data: ItemData

# --- Node References ---
@onready var sprite: Sprite2D = $Sprite2D

# --- Runtime Data ---
var final_item_data: ItemData
var is_player_overlapping: bool = false

func _ready() -> void:
	# Connect both entering and exiting signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_item_properties()

func _unhandled_input(event: InputEvent) -> void:
	# If the player is on top of the item and presses the interact button
	if is_player_overlapping and event.is_action_pressed("ui_interact"):
		_collect_item()

# Determines whether to use local inspector variables or global resource
func _setup_item_properties() -> void:
	if item_data:
		final_item_data = item_data.duplicate() as ItemData
	else:
		final_item_data = ItemData.new()
	
	if not item_name_override.is_empty():
		final_item_data.item_name = item_name_override
	if not description_override.is_empty():
		final_item_data.description = description_override
		
	var final_texture: Texture2D = null
	
	if use_atlas_cutting and sprite_sheet != null:
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = sprite_sheet
		atlas_tex.region = region_rect
		final_texture = atlas_tex
	elif texture_override != null:
		final_texture = texture_override
	else:
		final_texture = final_item_data.texture

	final_item_data.texture = final_texture
		
	if sprite and final_texture:
		sprite.texture = final_texture
		if filter_nearest:
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_overlapping = true
		print("[Pickup] Milo is standing on: ", final_item_data.item_name, " - Press Action Button to pick up!")

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_player_overlapping = false

func _collect_item() -> void:
	if final_item_data:
		GameManager.add_item(final_item_data)
		print("[Pickup] Milo successfully collected: ", final_item_data.item_name)
	
	# Turn off processing to prevent double triggers before freeing the node
	is_player_overlapping = false
	queue_free()
