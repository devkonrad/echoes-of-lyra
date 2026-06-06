extends CharacterBody2D
class_name BattleEntity

# --- New Signal for Targeting ---
signal entity_clicked(clicked_entity: BattleEntity)

@export_category("Base Stats")
@export var entity_name: String = "Unknown"
@export var max_health: int = 10
@export var current_health: int = 10
@export var attack_power: int = 2
@export var armor_class: int = 10

# Life information
@onready var health_bar: ProgressBar = $UI/HealthBar

var is_defending: bool = false
var is_attacking: bool = false
var original_battle_position: Vector2 = Vector2.ZERO

signal health_changed(current: int, max_hp: int)
signal fainted

# Damage popup scene
const DAMAGE_POPUP_SCENE = preload("res://scenes/damage_popup.tscn")

func _ready() -> void:
	# Enable input processing for mouse clicks dynamically just in case
	input_pickable = true

	# Initite the lifebar
	_update_health_ui()

# Godot's native callback for mouse interactions on CollisionObjects
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			entity_clicked.emit(self)
			return

func take_damage(amount: int) -> void:
	var final_damage: int = amount
	if is_defending:
		final_damage = max(1, int(amount / 2.0))
	
	current_health = max(0, current_health - final_damage)
	emit_signal("health_changed", current_health, max_health)
	
	# Updates the lifebar
	_update_health_ui()
	
	if current_health <= 0:
		_die()

# Damage popup
func spawn_damage_popup(text: String, color: Color = Color.WHITE) -> void:
	var popup = DAMAGE_POPUP_SCENE.instantiate()
	popup.text = text
	popup.modulate = color
	
	# Add the popup
	get_tree().current_scene.add_child(popup)
	
	# position adjustments
	popup.global_position = global_position + Vector2(0, 0)

# Lifebar
func _update_health_ui() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

# Dash attack
func dash_and_attack(target_global_pos: Vector2) -> void:
	if is_attacking:
		return
		
	is_attacking = true
	original_battle_position = global_position
	
	# Dash attack
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var attack_position: Vector2 = target_global_pos + Vector2(0, -20)
	tween.tween_property(self, "global_position", attack_position, 0.25)
	
	# Dash back
	tween.tween_callback(func():
		var sprite = get_node_or_null("Sprite")
		if sprite and sprite.has_signal("animation_finished"):			
			sprite.play("attack")
	)

func _die() -> void:
	emit_signal("fainted")
	queue_free()
