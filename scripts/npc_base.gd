## Base node interaction class representing overworld characters and story anchors.
extends Area2D

@export var npc_name: String = "Tallen"
@export var npc_portrait: Texture2D
@export var npc_sprite_frames: SpriteFrames

## Replace the flat String Array with an explicit path layout to the target JSON file
@export_file("*.json") var dialogue_file_path: String = ""

@onready var animated_sprite: AnimatedSprite2D = $animated_sprite

var player_in_range: bool = false

func _ready() -> void:
	if npc_sprite_frames and animated_sprite:
		animated_sprite.sprite_frames = npc_sprite_frames
		animated_sprite.play("idle")
	
	# Safe default execution anchor fallback
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		# Trigger dialogue execution if the dialogue container screen is not active
		if DialogManager.dialogue_hud and not DialogManager.dialogue_hud.visible:
			_start_conversation()

func _start_conversation() -> void:
	if dialogue_file_path.is_empty():
		print("[NpcBase] Error: No dialogue JSON file assigned to ", npc_name)
		return
		
	print("[NpcBase] Feeding structural database to HistoryManager...")
	
	# 1. Instruct the history core to cache and structure the targeted text file layout
	var is_success = HistoryManager.load_dialogue_file(dialogue_file_path)
	
	if is_success:
		# 2. Fire the global DialogManager execution pipeline
		# Note: We pass the NPC name and avatar so the frontend HUD layout can adapt dynamically
		DialogManager.start_dialogue(npc_name, npc_portrait)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
