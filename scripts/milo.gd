extends CharacterBody2D

# --- Dialogue and Identity Assets ---
@export var milo_portrait: Texture2D

# --- Movement Constants ---
@export var TILE_SIZE: int = 16
@export var WALK_SPEED: float = 7.5     # Tiles por segundo (Ajuste para mudar a velocidade)
@export var STEALTH_SPEED: float = 4.0   # Tiles por segundo no modo stealth

# --- Character States ---
enum States { IDLE, WALK, STEALTH }
var current_state: States = States.IDLE

# --- Node References ---
@onready var color_rect: ColorRect = $ColorRect

# --- Grid-based variables ---
var input_vector: Vector2 = Vector2.ZERO
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Garante que o personagem comece perfeitamente alinhado à grade de 16px
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	target_position = position

	$Sprite.play("idle")

func _physics_process(delta: float) -> void:
	_handle_stealth_toggle()
	
	if not is_moving:
		_get_input()
		if input_vector != Vector2.ZERO:
			_start_move()
	
	if is_moving:
		_continue_move(delta)
	
	_update_visuals()

# 1. Captures the player input (Strict 4-direction or 8-direction grid)
func _get_input() -> void:
	input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_vector = Vector2.RIGHT
		$Sprite.flip_h=false
		$Sprite.play("walking")
	elif Input.is_action_pressed("move_left"):
		input_vector = Vector2.LEFT
		$Sprite.flip_h=true
		$Sprite.play("walking")
	elif Input.is_action_pressed("move_down"):
		input_vector = Vector2.DOWN
		$Sprite.play("walking")
	elif Input.is_action_pressed("move_up"):
		input_vector = Vector2.UP
		$Sprite.play("walking")
	else:
		$Sprite.play("idle")

# 2. Manages stealth toggle separate from movement state
func _handle_stealth_toggle() -> void:
	if Input.is_action_just_pressed("toggle_stealth"):
		if current_state == States.STEALTH:
			current_state = States.IDLE
		else:
			current_state = States.STEALTH

# 3. Initiates the movement to the next tile
func _start_move() -> void:
	var target_speed = WALK_SPEED if current_state != States.STEALTH else STEALTH_SPEED
	
	# Calculates the next exact tile position
	target_position = position + (input_vector * TILE_SIZE)
	
	# --- Collision Check ---
	# test_move checks if moving to the next tile would collide with something
	if not test_move(transform, input_vector * TILE_SIZE):
		is_moving = true
		if current_state != States.STEALTH:
			current_state = States.WALK
	else:
		# If there is a wall, reset target so player can change direction instantly
		target_position = position

# 4. Interpolates position towards the target tile
func _continue_move(delta: float) -> void:
	var current_speed = WALK_SPEED if current_state != States.STEALTH else STEALTH_SPEED
	
	# Moves the character linearly towards the target tile
	position = position.move_toward(target_position, current_speed * TILE_SIZE * delta)
	
	# Checks if the target tile has been reached
	if position == target_position:
		is_moving = false
		if current_state != States.STEALTH:
			current_state = States.IDLE

# 5. Updates placeholder visuals
func _update_visuals() -> void:
	if current_state == States.STEALTH:
		color_rect.modulate = Color(1, 1, 1, 0.4)
	else:
		color_rect.modulate = Color(1, 1, 1, 1)
