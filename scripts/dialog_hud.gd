extends Control

# --- Node References ---
@onready var text_box: PanelContainer = $TextBox
@onready var portrait_rect: TextureRect = $TextBox/MarginContainer/HBoxContainer/Portrait
@onready var dialogue_label: RichTextLabel = $TextBox/MarginContainer/HBoxContainer/DialogLabel
@onready var letter_timer: Timer = $LetterTimer

# --- Dialogue Variables ---
var dialog_lines: Array[String] = []
var current_line_index: int = 0
var is_typing: bool = false

# --- Dialogue Configuration ---
@export var milo_portrait: Texture2D
var active_npc_portrait: Texture2D = null

signal dialogue_finished

func _ready() -> void:
	# O timer precisa ser "One Shot" (roda uma vez por gatilho)
	letter_timer.one_shot = true
	letter_timer.timeout.connect(_on_letter_timer_timeout)
	
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and visible:		
		get_viewport().set_input_as_handled()

		if is_typing:
			# Se ainda está digitando, mostra a linha inteira imediatamente
			_finish_typing_instantly()
		else:
			# Se já terminou de digitar, avança para a próxima linha
			_advance_dialogue()


func start_dialogue(lines: Array[String], npc_portrait: Texture2D) -> void:
	dialog_lines = lines
	active_npc_portrait = npc_portrait # Saves the NPC picture
	current_line_index = 0
	show()
	_display_current_line()


func _display_current_line() -> void:
	if current_line_index < dialog_lines.size():
		is_typing = true
		var full_text: String = dialog_lines[current_line_index]
		
		# Checks the Avatar
		if full_text.begins_with("Milo:"):
			portrait_rect.texture = GameManager.milo_portrait
			dialogue_label.text = full_text.replace("Milo:", "").strip_edges()
		else:
			portrait_rect.texture = active_npc_portrait
			dialogue_label.text = full_text.strip_edges()
			
		print(dialogue_label.text)
		dialogue_label.visible_characters = 0
		letter_timer.start()
	else:
		_close_dialogue()

func _on_letter_timer_timeout() -> void:
	if dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		dialogue_label.visible_characters += 1
		letter_timer.start() # Reinicia o timer para a próxima letra
	else:
		is_typing = false

func _finish_typing_instantly() -> void:
	letter_timer.stop()
	dialogue_label.visible_characters = dialogue_label.get_total_character_count()
	is_typing = false

func _advance_dialogue() -> void:
	current_line_index += 1
	
	if current_line_index >= dialog_lines.size():
		_close_dialogue()
	else:
		_display_current_line()

func _close_dialogue() -> void:
	hide()
	dialog_lines.clear()
	dialogue_finished.emit() # Marks the conversation as empty
	
	GameManager.milo.set_physics_process(true)
