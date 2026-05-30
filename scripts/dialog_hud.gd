extends Control

# --- Node References ---
@onready var text_box: PanelContainer = $TextBox
@onready var dialogue_label: RichTextLabel = $TextBox/MarginContainer/DialogLabel
@onready var letter_timer: Timer = $TextBox/LetterTimer

# --- Dialogue Variables ---
var dialog_lines: Array[String] = []
var current_line_index: int = 0
var is_typing: bool = false

signal dialogue_finished

func _ready() -> void:
	# O timer precisa ser "One Shot" (roda uma vez por gatilho)
	letter_timer.one_shot = true
	letter_timer.timeout.connect(_on_letter_timer_timeout)
	
	hide()

func _unhandled_input(event: InputEvent) -> void:
	# Usa uma ação que você já deve ter configurada (ex: "ui_accept", "interact", etc.)
	if event.is_action_pressed("ui_accept") and visible:		
		get_viewport().set_input_as_handled()

		if is_typing:
			# Se ainda está digitando, mostra a linha inteira imediatamente
			_finish_typing_instantly()
		else:
			# Se já terminou de digitar, avança para a próxima linha
			_advance_dialogue()

# Função pública que os NPCs vão chamar para iniciar a conversa
func start_dialogue(lines: Array[String]) -> void:
	dialog_lines = lines
	current_line_index = 0
	show()
	_display_current_line()

func _display_current_line() -> void:
	if current_line_index < dialog_lines.size():
		is_typing = true
		dialogue_label.text = dialog_lines[current_line_index]
		print(dialogue_label.text)
		
		# Começa mostrando 0 caracteres e liga o timer
		dialogue_label.visible_characters = 0
		
		letter_timer.start()
	else:
		# Acabaram as linhas de diálogo, fecha a HUD
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
	dialogue_finished.emit() # Avisa o GameManager que a conversa acabou!
