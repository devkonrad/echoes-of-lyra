extends CharacterBody2D

# --- Assets & Configs ---
@export var milo_portrait: Texture2D
@export var TILE_SIZE: int = 16
@export var WALK_SPEED: float = 7.5
@export var STEALTH_SPEED: float = 4.0

enum States { IDLE, WALK, STEALTH }
var current_state: States = States.IDLE

# --- Combat & Hit Recovery ---
@export var invulnerability_duration: float = 1.0
var is_invulnerable: bool = false
var is_attacking: bool = false
var original_battle_position: Vector2 = Vector2.ZERO

# --- Nodes ---
@onready var color_rect: ColorRect = $ColorRect
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_area: Area2D = $AttackArea

# --- Grid Vectors ---
var input_vector: Vector2 = Vector2.ZERO
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO

signal health_changed(new_health: int)

func _ready() -> void:
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	target_position = position
	sprite.play("idle")
	sprite.animation_finished.connect(_on_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	if is_attacking:
		return
		
	_handle_stealth_toggle()
	_handle_attack_input()
	
	if not is_moving:
		_get_input()
		if input_vector != Vector2.ZERO:
			_start_move()
	else:
		_continue_move(delta)
	
	_update_visuals()

func _get_input() -> void:
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_vector = Vector2.RIGHT
		sprite.flip_h = false
		sprite.play("walking")
	elif Input.is_action_pressed("move_left"):
		input_vector = Vector2.LEFT
		sprite.flip_h = true
		sprite.play("walking")
	elif Input.is_action_pressed("move_down"):
		input_vector = Vector2.DOWN
		sprite.play("walking")
	elif Input.is_action_pressed("move_up"):
		input_vector = Vector2.UP
		sprite.play("walking")
	elif not is_attacking:
		sprite.play("idle")

func _handle_stealth_toggle() -> void:
	if Input.is_action_just_pressed("toggle_stealth"):
		current_state = States.IDLE if current_state == States.STEALTH else States.STEALTH

func _handle_attack_input() -> void:
	if not is_moving and Input.is_action_just_pressed("ui_attack"):
		give_attack()

func _start_move() -> void:
	target_position = position + (input_vector * TILE_SIZE)
	
	if not test_move(transform, input_vector * TILE_SIZE):
		is_moving = true
		if current_state != States.STEALTH:
			current_state = States.WALK
	else:
		target_position = position

func _continue_move(delta: float) -> void:
	var current_speed = WALK_SPEED if current_state != States.STEALTH else STEALTH_SPEED
	position = position.move_toward(target_position, current_speed * TILE_SIZE * delta)
	
	if position == target_position:
		is_moving = false
		if current_state != States.STEALTH:
			current_state = States.IDLE

func _update_visuals() -> void:
	color_rect.modulate = Color(1, 1, 1, 0.4) if current_state == States.STEALTH else Color(1, 1, 1, 1)

# --> OVERWORLD HEALTH & DAMAGE MECHANICS

func take_damage(amount: int) -> void:
	if is_invulnerable:
		return
		
	if typeof(PlayerStateManager) != TYPE_NIL:
		PlayerStateManager.take_damage(amount, true)
		health_changed.emit(PlayerStateManager.current_health)
		
	_trigger_hit_recovery()

func _trigger_hit_recovery() -> void:
	is_invulnerable = true
	_flash_sprite_loop()
	await get_tree().create_timer(invulnerability_duration).timeout
	is_invulnerable = false

func _flash_sprite_loop() -> void:
	while is_invulnerable:
		sprite.modulate = Color(15, 15, 15, 1)
		await get_tree().create_timer(0.1).timeout
		if not is_invulnerable: break
		sprite.modulate = Color(1, 1, 1, 1)
		await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1, 1)

# --> OVERWORLD OFFENSIVE ATTACK MECHANICS

func give_attack() -> void:
	if is_attacking:
		return
		
	is_attacking = true
	
	# Clean and direct animation execution
	sprite.stop()
	sprite.animation = "left_attack"
	sprite.frame = 0
	sprite.play()
	
	for body in attack_area.get_overlapping_bodies():
		if body is EnemyPatrolBase:
			body.take_damage(1)

	# Safety release timer matching a 16 FPS animation setup
	await get_tree().create_timer(0.25).timeout
	
	if is_instance_valid(self):
		is_attacking = false
		sprite.play("idle")

# --> BATTLE METHODS (Arena System Core)

func dash_and_attack(target_global_pos: Vector2) -> void:
	if is_attacking:
		return
		
	is_attacking = true
	original_battle_position = global_position 
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var attack_position: Vector2 = target_global_pos + Vector2(0, 10)
	tween.tween_property(self, "global_position", attack_position, 0.25)
	tween.tween_callback(attack)

func attack() -> void:
	sprite.play("attack")

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "attack":
		var tween_back: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween_back.tween_property(self, "global_position", original_battle_position, 0.25)
		tween_back.tween_callback(func():
			is_attacking = false
			sprite.play("idle")
		)
