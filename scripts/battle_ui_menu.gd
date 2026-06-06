extends Control
class_name BattleUiMenu

signal attack_requested
signal defend_requested

@onready var attack_button: Button = $ActionMenu/HBoxContainer/AttackButton
@onready var defend_button: Button = $ActionMenu/HBoxContainer/DefendButton
@onready var turn_announcer: Label = $TurnAnnouncer

func _ready() -> void:
	# Connect Godot's button signals to our local handlers
	attack_button.pressed.connect(_on_attack_button_pressed)
	defend_button.pressed.connect(_on_defend_button_pressed)
	
	# Start hidden until the BattleRoom controller invokes it
	hide()
	if turn_announcer:
		turn_announcer.hide()


func open() -> void:
	show()
	if has_node("ActionMenu"):
		$ActionMenu.show()
	attack_button.disabled = false
	defend_button.disabled = false
	attack_button.grab_focus()


## Hides the menu and locks input during calculations or animations.
func close() -> void:
	hide()
	attack_button.disabled = true
	defend_button.disabled = true


func _on_attack_button_pressed() -> void:
	# Disabling buttons immediately prevents accidental double-inputs
	attack_button.disabled = true
	defend_button.disabled = true
	attack_requested.emit()


func _on_defend_button_pressed() -> void:
	attack_button.disabled = true
	defend_button.disabled = true
	defend_requested.emit()


## Displays a full-screen text announcement banner and executes an optional callback upon completion.
func announce_event(text_to_display: String, callback_on_finish: Callable = Callable()) -> void:
	if not turn_announcer:
		if callback_on_finish.is_valid():
			callback_on_finish.call()
		return
		
	# 1. VISIBILITY: Reveal parent layer, ensure action selection submenus are hidden
	show()
	if has_node("ActionMenu"):
		$ActionMenu.hide()
		
	# Inject the dynamic event message
	turn_announcer.text = text_to_display.to_upper()
	
	var tween: Tween = create_tween()
	
	# Reset state before animating
	turn_announcer.modulate.a = 0.0
	turn_announcer.show()
	
	# 2. FADE IN - Bring the banner text opacity up
	tween.tween_property(turn_announcer, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	# 3. SUSTAIN INTERVAL - Hold the text in place for pacing
	tween.tween_interval(1.0)
	
	# 4. FADE OUT - Animate banner opacity back to invisible
	tween.tween_property(turn_announcer, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	# 5. TEARDOWN - Safely hide the text label container
	tween.tween_callback(turn_announcer.hide)
	
	# 6. EXECUTION HOOK - If a valid callback configuration was provided, fire it here
	if callback_on_finish.is_valid():
		tween.tween_callback(callback_on_finish)
