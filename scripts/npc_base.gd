extends Area2D

@export var npc_name: String = "Tallen"
@export var npc_portrait: Texture2D
@export var npc_sprite_frames: SpriteFrames

@export var dialogue_lines: Array[String] = [
	"Milo: Hello, Tallen! Beautiful day, isn't it?",
	"NPC: Oh, Milo! Strange things are happening in the northern forest...",
	"NPC: Please take care out there!"
]

@onready var animated_sprite: AnimatedSprite2D = $animated_sprite

var player_in_range: bool = false

func _ready() -> void:
	if npc_sprite_frames and animated_sprite:
		animated_sprite.sprite_frames = npc_sprite_frames
		animated_sprite.play("idle")
		
	
	$animated_sprite.play("default")
	
	body_entered.connect(_on_body_entered)
	#body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		if DialogManager.dialogue_hud and not DialogManager.dialogue_hud.visible:
			#_start_conversation()
			print("Starts a conversation ...")
			_start_conversation()

func _start_conversation() -> void:
	print("[npc_base] Starting conversation with: ", npc_name)
	
	var formatted_lines: Array[String] = []
	for line in dialogue_lines:
		# Verifica usando o método correto do Godot 4 (begins_with)
		if line.begins_with("Milo:"):
			formatted_lines.append(line)
		elif line.begins_with("NPC:"):
			# Troca a tag genérica pelo nome real configurado neste NPC
			formatted_lines.append(line.replace("NPC:", npc_name + ":"))
		else:
			# Caso você esqueça de colocar a tag na fala, ele assume que é o NPC falando
			formatted_lines.append(npc_name + ": " + line)

	# IMPORTANTE: Passamos o array de falas E o avatar do NPC para o DialogManager
	DialogManager.start_dialogue(formatted_lines, npc_portrait)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
