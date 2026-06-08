## Controls the text typing effects, active speaker portraits, and branch choice selections.
extends Control

# --- Node References ---
@onready var text_box: PanelContainer = $TextBox
@onready var portrait_rect: TextureRect = $TextBox/MarginContainer/HBoxContainer/Portrait
@onready var dialogue_label: RichTextLabel = $TextBox/MarginContainer/HBoxContainer/DialogLabel
@onready var letter_timer: Timer = $LetterTimer
## THE NEW HOOK: Reference to the choice injection vertical box layout
@onready var choice_container: VBoxContainer = $ChoiceContainer

# --- Dialogue Interaction Variables ---
var is_typing: bool = false
var active_npc_name: String = ""
var active_npc_portrait: Texture2D = null
## State lock to block inputs while choice buttons are active on screen
var is_waiting_for_choice: bool = false

signal dialogue_finished

func _ready() -> void:
	letter_timer.one_shot = true
	letter_timer.timeout.connect(_on_letter_timer_timeout)
	hide()
	_clear_choice_nodes()

func _input(event: InputEvent) -> void:
	# Prevent advancing if the screen is invisible or if we are locked waiting for a branching choice
	if not visible or is_waiting_for_choice:
		return
		
	if event.is_action_pressed("ui_accept"):        
		get_viewport().set_input_as_handled()

		if is_typing:
			_finish_typing_instantly()
		else:
			_advance_dialogue()

func start_dialogue(npc_name: String, npc_portrait: Texture2D) -> void:
	active_npc_name = npc_name
	active_npc_portrait = npc_portrait
	is_waiting_for_choice = false
	_clear_choice_nodes()
	show()
	_display_current_node()

func _display_current_node() -> void:
	_clear_choice_nodes()
	is_waiting_for_choice = false
	
	var current_node: Dictionary = HistoryManager.get_current_node()
	
	if current_node.is_empty() or HistoryManager.current_node_id == "end_nodes":
		_close_dialogue()
		return
		
	is_typing = true
	var raw_text: String = current_node.get("text", "")
	var speaker_type: String = current_node.get("speaker_type", "npc")
	
	if speaker_type == "milo":
		portrait_rect.texture = GameManager.milo_portrait
		dialogue_label.text = "Milo: " + raw_text
	elif speaker_type == "npc":
		portrait_rect.texture = active_npc_portrait
		dialogue_label.text = active_npc_name + ": " + raw_text
	else:
		portrait_rect.texture = null
		dialogue_label.text = raw_text

	dialogue_label.visible_characters = 0
	letter_timer.start()

func _on_letter_timer_timeout() -> void:
	if dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		dialogue_label.visible_characters += 1
		letter_timer.start()
	else:
		_on_typing_completed()

func _finish_typing_instantly() -> void:
	letter_timer.stop()
	dialogue_label.visible_characters = dialogue_label.get_total_character_count()
	_on_typing_completed()

## Triggered automatically whenever a dialogue block finishes drawing characters.
func _on_typing_completed() -> void:
	is_typing = false
	
	var current_node: Dictionary = HistoryManager.get_current_node()
	var choices: Array = current_node.get("choices", [])
	
	# If the text finished typing AND there are multiple choices, we must build the options UI
	if choices.size() > 1:
		_build_choice_interface(choices)

## Instantiates native Button nodes dynamically based on the JSON choices graph array layout.
func _build_choice_interface(choices: Array) -> void:
	is_waiting_for_choice = true
	_clear_choice_nodes()
	
	for i in range(choices.size()):
		var choice_data: Dictionary = choices[i]
		
		# Create a native UI button on the fly
		var btn = Button.new()
		btn.text = choice_data.get("text", "...")
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		
		# Optional: apply pixel-art UI button themes here if you have them configured
		
		# Connect the press event to our receiver function using a Callable lambda bind
		btn.pressed.connect(_on_choice_button_pressed.bind(i))
		
		choice_container.add_child(btn)
	
	# Accessibility: Automatically focus the first button so keyboard/controller navigation works natively
	if choice_container.get_child_count() > 0:
		choice_container.get_child(0).grab_focus()

## Receiver hook activated when a dynamically spawned branch button gets pressed.
func _on_choice_button_pressed(choice_index: int) -> void:
	_clear_choice_nodes()
	HistoryManager.advance_dialogue_by_choice(choice_index)
	_display_current_node()

func _advance_dialogue() -> void:
	var current_node: Dictionary = HistoryManager.get_current_node()
	var choices: Array = current_node.get("choices", [])
	
	# If there's only 1 choice (like a single "Continue" button or implicit path), advance instantly
	if choices.size() <= 1:
		HistoryManager.advance_dialogue_by_choice(0)
		_display_current_node()

## Clears out all old button nodes safely from runtime tree memory blocks.
func _clear_choice_nodes() -> void:
	if choice_container:
		for child in choice_container.get_children():
			child.queue_free()

func _close_dialogue() -> void:
	_clear_choice_nodes()
	hide()
	dialogue_finished.emit()
	DialogManager.end_dialogue()
