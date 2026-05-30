extends Area2D

@export var npc_name: String = "NPC"
@export var dialogue_lines: Array[String] = [
	"Ola, Milo! Voce viu o tempo hoje?",
	"Dizem que coisas estranhas andam acontecendo na floresta ao norte...",
	"Tome cuidado por ai!"
]

var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	# Only allow interaction if the player is in range AND a dialogue is NOT already active
	if player_in_range and event.is_action_pressed("ui_accept"):
		if GameManager.dialogue_hud and not GameManager.dialogue_hud.visible:
			_start_conversation()

func _start_conversation() -> void:
	print("[npc_base] start conversation...")
	
	var formatted_lines: Array[String] = []
	for line in dialogue_lines:
		formatted_lines.append(npc_name + ": " + line)

	# Call start dialog at GameManager
	GameManager.start_dialogue(formatted_lines)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
