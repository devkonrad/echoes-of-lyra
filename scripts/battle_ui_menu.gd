extends Control
class_name BattleUiMenu

signal attack_requested
signal defend_requested

@onready var attack_button: Button = $ActionMenu/HBoxContainer/AttackButton
@onready var defend_button: Button = $ActionMenu/HBoxContainer/DefendButton
@onready var turn_announcer: Label = $TurnAnnouncer
@onready var milo_battle_bar: ProgressBar = $MiloBattleBar

func _ready() -> void:
	# Connect Godot's button signals to our local handlers
	attack_button.pressed.connect(_on_attack_button_pressed)
	defend_button.pressed.connect(_on_defend_button_pressed)

	# Connect PlayerStateManager battle health signal to update our vertical bar
	PlayerStateManager.battle_health_changed.connect(_on_milo_battle_health_changed)
	
	# Initialize health bar values safely on startup so it doesn't load empty
	if milo_battle_bar:
		milo_battle_bar.max_value = PlayerStateManager.max_battle_health
		milo_battle_bar.value = PlayerStateManager.current_battle_health
	
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


## Triggered automatically whenever Milo takes damage or heals during combat rounds
func _on_milo_battle_health_changed(current: int, max_hp: int) -> void:
	if milo_battle_bar:
		milo_battle_bar.max_value = max_hp
		milo_battle_bar.value = current


## Displays a full-screen text announcement banner and executes an optional callback upon completion.
func announce_event(text_to_display: String, callback_on_finish: Callable = Callable()) -> void:
	if not turn_announcer:
		if callback_on_finish.is_valid():
			callback_on_finish.call()
		return
		
	# Reveal parent layer, ensure action selection submenus are hidden
	show()
	if has_node("ActionMenu"):
		$ActionMenu.hide()
		
	# Safety check: Prevent the health bar from showing up during end-game screens
	var upper_text: String = text_to_display.to_upper()
	if "WIN" in upper_text or "LOST" in upper_text or "SORRY" in upper_text or "GOT" in upper_text:
		if milo_battle_bar:
			milo_battle_bar.hide()
	else:
		if milo_battle_bar:
			milo_battle_bar.show()
		
	# Inject the dynamic event message
	turn_announcer.text = text_to_display.to_upper()
	
	var tween: Tween = create_tween()
	
	# Reset state before animating
	turn_announcer.modulate.a = 0.0
	turn_announcer.show()
	
	# FADE IN - Bring the banner text opacity up
	tween.tween_property(turn_announcer, "modulate:a", 1.0, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	# SUSTAIN INTERVAL - Hold the text in place for pacing
	tween.tween_interval(0.9)
	
	# FADE OUT - Animate banner opacity back to invisible
	tween.tween_property(turn_announcer, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	# TEARDOWN - Safely hide the text label container
	tween.tween_callback(turn_announcer.hide)
	
	# EXECUTION HOOK - If a valid callback configuration was provided, fire it here
	if callback_on_finish.is_valid():
		tween.tween_callback(callback_on_finish)
