class_name EnemyPatrolBase
extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, FATIGUED }

# Defeated signal (for callbacks )
signal defeated

# --- Movement System ---
@export_group("Movement System")
@export var patrol_speed: float = 35.0
@export var chase_speed: float = 65.0
@export var idle_duration: float = 2.0

# --- Exhaustion System ---
@export_group("Exhaustion System")
@export var max_chase_duration: float = 4.0
@export var fatigue_duration: float = 3.0

# --- Detection Layout ---
@export_group("Detection Layout")
@export var patrol_radius: float = 70.0

# --- Combat & Loot Stats ---
@export_group("Combat & Loot Stats")
@export var max_health: int = 3
@export var custom_item_drop: ItemData
@export_range(0.0, 1.0) var drop_chance: float = 1.0

# --- Node References ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var vision_area: Area2D = $VisionArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var health_bar: ProgressBar = $HealthBarLayout/HealthBar

# --- State Tracker Variables ---
var current_state: State = State.IDLE
var state_timer: float = 0.0
var chase_timer: float = 0.0
var spawn_position: Vector2
var target_position: Vector2
var target_player: CharacterBody2D = null

# --- Local Combat Trackers ---
var current_health: int
var is_dead: bool = false

# --- Preloaded Loot Assets ---
const PICKUP_ITEM_SCENE = preload("res://scenes/pickup_item.tscn")

func _ready() -> void:
	current_health = max_health
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false
		
	spawn_position = global_position
	
	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	if sprite:
		sprite.animation_finished.connect(_on_sprite_animation_finished)
	
	_choose_new_patrol_target()
	_change_state(State.IDLE)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	match current_state:
		State.IDLE: _process_idle_state(delta)
		State.PATROL: _process_patrol_state(delta)
		State.CHASE: _process_chase_state(delta)
		State.FATIGUED: _process_fatigue_state(delta)
			
	move_and_slide()
	_animate_sprite()

func _change_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			state_timer = idle_duration
		State.PATROL:
			_choose_new_patrol_target()
		State.CHASE:
			chase_timer = max_chase_duration
		State.FATIGUED:
			velocity = Vector2.ZERO
			state_timer = fatigue_duration
			target_player = null

func _process_idle_state(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_change_state(State.PATROL)

func _process_patrol_state(_delta: float) -> void:
	var distance_to_target: float = global_position.distance_to(target_position)
	
	if distance_to_target > 4.0:
		velocity = (target_position - global_position).normalized() * patrol_speed
	else:
		velocity = Vector2.ZERO
		_change_state(State.IDLE)

func _process_chase_state(delta: float) -> void:
	chase_timer -= delta
	if chase_timer <= 0.0:
		_change_state(State.FATIGUED)
		return

	if is_instance_valid(target_player):
		velocity = (target_player.global_position - global_position).normalized() * chase_speed
	else:
		_change_state(State.IDLE)

func _process_fatigue_state(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_change_state(State.IDLE)

func _choose_new_patrol_target() -> void:
	var random_angle: float = randf() * TAU
	var random_distance: float = randf() * patrol_radius
	var offset: Vector2 = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	target_position = spawn_position + offset

func _animate_sprite() -> void:
	if sprite.animation == "attack" and sprite.is_playing():
		return
		
	if velocity.x > 0.1:
		sprite.flip_h = false
	elif velocity.x < -0.1:
		sprite.flip_h = true
		
	if current_state == State.CHASE or velocity.length() > 0.1:
		sprite.play("walk")
	else:
		sprite.play("idle")

# --- Combat and Loot Mechanics ---

func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	current_health = clampi(current_health - amount, 0, max_health)
	
	if health_bar:
		health_bar.visible = true
		health_bar.value = current_health
		
	_flash_damaged_feedback()
	
	if current_health <= 0:
		_die()

func _flash_damaged_feedback() -> void:
	var original_tint: Color = sprite.modulate
	sprite.modulate = Color(10, 1, 1, 1)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original_tint

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	
	# Emit the signal so level triggers can catch it
	defeated.emit()

	_process_loot_drop()
	queue_free()

func _process_loot_drop() -> void:
	if randf() > drop_chance:
		return
		
	var item_instance = PICKUP_ITEM_SCENE.instantiate()
	item_instance.global_position = global_position
	
	if custom_item_drop:
		item_instance.item_data = custom_item_drop
		
	get_parent().add_child(item_instance)

# --- Signal Connections ---

func _on_vision_area_body_entered(body: Node2D) -> void:
	if current_state == State.FATIGUED or is_dead:
		return
		
	if body.name == "Milo" or body.is_in_group("Player"):
		target_player = body as CharacterBody2D
		_change_state(State.CHASE)

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		if current_state == State.CHASE:
			_change_state(State.IDLE)

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if sprite.animation == "attack" and sprite.is_playing():
		return
		
	if current_state == State.FATIGUED or is_dead:
		return
		
	if body.name == "Milo" or body.is_in_group("Player"):
		target_player = body as CharacterBody2D
		_execute_attack_sequence()

func _execute_attack_sequence() -> void:
	velocity = Vector2.ZERO
	
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	else:
		if is_instance_valid(target_player) and target_player.has_method("take_damage"):
			target_player.take_damage(1)
		_change_state(State.IDLE)

func _on_sprite_animation_finished() -> void:
	if is_dead:
		return
		
	if sprite.animation == "attack":
		if is_instance_valid(target_player) and target_player.has_method("take_damage"):
			target_player.take_damage(1)
		
		var still_in_range: bool = false
		if hurtbox:
			for body in hurtbox.get_overlapping_bodies():
				if body == target_player:
					still_in_range = true
					break
					
		if still_in_range:
			_execute_attack_sequence()
		else:
			_change_state(State.CHASE if is_instance_valid(target_player) else State.IDLE)
