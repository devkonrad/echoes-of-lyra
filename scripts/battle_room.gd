## Manages the core combat loop, state transitions, and turn progression.
##
## Acts as the central controller for the battle arena, handling enemy spawning,
## turn orchestration, and victory/defeat evaluation.
extends Node
class_name BattleRoom

# --- State Machine ---

## Defines all possible phases of a combat encounter.
enum BattleState {
	START,           ## Initial setup phase (music, graphics, preparation).
	PLAYER_TURN,     ## Awaiting interaction and decisions from the player.
	ENEMY_TURN,      ## Processing enemy behaviors and actions.
	CHECK_WIN_LOSS,  ## Evaluating health pools and remaining active entities.
	NEXT_WAVE,       ## Incrementing encounter progress and preparing the next wave.
	VICTORY,         ## Handling successful encounter completion rewards and exit.
	DEFEAT           ## Handling player failure state and game over flows.
}

# --- Node References ---

@onready var music_player: AudioStreamPlayer2D = $MusicPlayer

@onready var spawn_01: Marker2D = $EnemyPositions/enemy_spawn_01
@onready var spawn_02: Marker2D = $EnemyPositions/enemy_spawn_02
@onready var spawn_03: Marker2D = $EnemyPositions/enemy_spawn_03

# Damage popup scene
const DAMAGE_POPUP_SCENE = preload("res://scenes/damage_popup.tscn")

# Victory ItemScene
const VICTORY_DROP_SCENE = preload("res://scenes/victory_drop.tscn")

# Milo Spawn Point
@onready var hero_spawn: Marker2D = $hero_spawn

# Exit door
@onready var exit_door: Node2D = $ExitDoor

# --- Global UI Bindings ---
@onready var UiCanvas: CanvasLayer = GameManager.global_gui

# --- Properties & Tracking ---

## Runtime collection of valid positioning markers for enemies.
var enemy_spawns: Array[Marker2D] = []

## References to actively living enemy instances in the current wave.
var active_enemies: Array[Node] = []

## Tracks the current operational phase of the battlefield.
var current_state: BattleState = BattleState.START

## Pointer index for the active combat wave within the injected encounter data.
var current_wave_index: int = 0

## Tracks which enemy's turn it is to strike during the round loop.
var current_enemy_index: int = 0

## The active data architecture containing waves, music, and layout metadata.
var current_encounter: BattleEncounter

## Tracks if the player has clicked "Attack" and is currently choosing which enemy to hit.
var is_selecting_target: bool = false

# --- Lifecycle Methods ---

func _ready() -> void:
	_ensure_markers_ready()
	_connect_ui_signals()
	print("[Battle] BattleRoom loaded in tree. Waiting for data injection...")


# --- Public Initialization Api ---

## Injects runtime encounter configurations and starts the combat state engine.
## Called externally by the SceneManager before transitions complete.
func init_battle(encounter_data: BattleEncounter) -> void:
	if not is_inside_tree():
		await ready

	_ensure_markers_ready()
	current_encounter = encounter_data
	current_wave_index = 0
	current_enemy_index = 0
	print("[Battle] Data successfully injected by SceneManager.")
	
	_enter_state(BattleState.START)


# --- Core State Controller ---

## Orchestrates state switches and executes corresponding handler logic.
func _enter_state(new_state: BattleState) -> void:
	match new_state:
		BattleState.START:
			current_state = new_state
			_setup_battle()
		BattleState.PLAYER_TURN:
			current_state = new_state
			_start_player_turn()
		BattleState.ENEMY_TURN:
			current_state = new_state
			_start_enemy_turn()
		BattleState.CHECK_WIN_LOSS:
			# We DO NOT overwrite current_state with CHECK_WIN_LOSS here.
			# This allows _check_rules() to see if we just came from PLAYER_TURN or ENEMY_TURN.
			_check_rules()
		BattleState.NEXT_WAVE:
			current_state = new_state
			_advance_wave()
		BattleState.VICTORY:
			current_state = new_state
			_end_battle(true)
		BattleState.DEFEAT:
			current_state = new_state
			_end_battle(false)


# --- Private Battle Flow Handlers ---

## Guards against early data injections by initializing spawn points on demand.
func _ensure_markers_ready() -> void:
	if enemy_spawns.is_empty():
		enemy_spawns = [spawn_01, spawn_02, spawn_03]
		print("[Battle] Spawn markers registered safely: ", enemy_spawns.size())


## Connects the modular battle UI signals from the global Canvas Layer to this room.
func _connect_ui_signals() -> void:
	if UiCanvas and UiCanvas.battle_ui_menu:
		if not UiCanvas.battle_ui_menu.attack_requested.is_connected(_on_ui_attack_requested):
			UiCanvas.battle_ui_menu.attack_requested.connect(_on_ui_attack_requested)
		if not UiCanvas.battle_ui_menu.defend_requested.is_connected(_on_ui_defend_requested):
			UiCanvas.battle_ui_menu.defend_requested.connect(_on_ui_defend_requested)
		print("[Battle] UI Signals connected successfully.")


## Handles basic spatial layout setups, asset binding, and audio pipelines.
func _setup_battle() -> void:
	print("[Battle] Setting up battlefield...")
	
	# Hides the door
	if is_instance_valid(exit_door):
			exit_door.visible = false

	# Guard Clause: Ensure encounter data is present
	if not current_encounter:
		print("[Battle] Error: No encounter data provided to BattleRoom!")
		_enter_state(BattleState.DEFEAT)
		return
		
	# Guard Clause: Ensure the essential hero spawn marker exists in the scene
	if not is_instance_valid(hero_spawn):
		print("[Battle] Error: Critical 'hero_spawn' marker missing in BattleRoom scene!")
		_enter_state(BattleState.DEFEAT)
		return

	# Reset Milo's combat-specific health pool to max before spawning
	PlayerStateManager.reset_battle_health()

	# Play combat music dynamically if available
	if current_encounter.battle_music:
		music_player.stream = current_encounter.battle_music
		music_player.play()

	# Instantiate Milo safely at the validated spawn marker location
	GameManager.spawn_milo(hero_spawn.global_position)

	# Trigger the animation and let ITS callback handle the spawning.
	if UiCanvas and UiCanvas.battle_ui_menu:
		UiCanvas.battle_ui_menu.announce_event(
			"Battle Started!",
			_spawn_current_wave
		)
	else:
		_spawn_current_wave()


## Instantiates enemy scenes bound to the current wave into registered spawn positions.
func _spawn_current_wave() -> void:
	active_enemies.clear()
	current_enemy_index = 0
	
	if current_wave_index >= current_encounter.waves.size():
		_enter_state(BattleState.VICTORY)
		return
		
	var wave_resource: Resource = current_encounter.waves[current_wave_index]
	if not wave_resource or not "enemies" in wave_resource:
		print("[Battle] Error: Invalid wave resource at index ", current_wave_index)
		_enter_state(BattleState.DEFEAT)
		return
		
	var enemy_scenes: Array = wave_resource.enemies
	
	for i in range(enemy_scenes.size()):
		if i >= enemy_spawns.size():
			print("[Battle] Warning: More enemies than available spawn markers!")
			break
			
		if enemy_scenes[i]:
			var enemy_instance: Node = enemy_scenes[i].instantiate()
			enemy_spawns[i].add_child(enemy_instance)
			active_enemies.append(enemy_instance)
			
			# Connect the click signal for target selection
			if enemy_instance is BattleEntity:
				enemy_instance.entity_clicked.connect(_on_enemy_selected)
			
	print("[Battle] Wave ", current_wave_index + 1, " spawned with ", active_enemies.size(), " enemies.")
	_enter_state(BattleState.PLAYER_TURN)


## Pauses automation workflows and signals interface hooks to wait for player input.
func _start_player_turn() -> void:
	print("[Battle] Milo's turn! Waiting for player input...")
	
	# Reset Milo's defense stance at the start of his turn
	PlayerStateManager.is_defending = false
	is_selecting_target = false
	
	# Triggers the visual screen overlay announcement via Tween animation
	if UiCanvas and UiCanvas.battle_ui_menu:
		UiCanvas.battle_ui_menu.announce_event(
			"Your Turn!",
			UiCanvas.battle_ui_menu.open
		)


## Triggered when player clicks "[ Attack ]" in the UI menu.
func _on_ui_attack_requested() -> void:
	if current_state != BattleState.PLAYER_TURN:
		return
		
	# Hide the action menu to clear the screen
	if UiCanvas and UiCanvas.battle_ui_menu:
		UiCanvas.battle_ui_menu.close()

		UiCanvas.battle_ui_menu.announce_event(
			"Click over an enemy to attack!"
		)
	
	# Enable targeting IMMEDIATELY so fast clicks are registered without waiting timers
	is_selecting_target = true


## Route UI trigger to put Milo into a defensive guard stance.
func _on_ui_defend_requested() -> void:
	execute_player_defend()


## Triggered when the user physically clicks on an enemy body in the viewport.
func _on_enemy_selected(target_enemy: BattleEntity) -> void:
	if current_state != BattleState.PLAYER_TURN or not is_selecting_target:
		return
		
	var target_index: int = active_enemies.find(target_enemy)
	
	if target_index != -1:
		is_selecting_target = false
		execute_player_attack(target_index)
	else:
		print("[Battle] Error: Clicked entity is not in the active enemy registry.")

## Evaluates structural validity of actions taken against a targeted index slot.
func execute_player_attack(target_index: int) -> void:
	if current_state != BattleState.PLAYER_TURN:
		print("[Battle] Cannot attack! It is not Milo's turn.")
		return
		
	if target_index >= active_enemies.size() or not is_instance_valid(active_enemies[target_index]):
		print("[Battle] Invalid enemy target!")
		return
		
	var target_enemy: BattleEntity = active_enemies[target_index] as BattleEntity
	print("[Battle] Milo attacks ", target_enemy.entity_name, " at slot: ", target_index)
	
	# Trigger Milo's dash attack
	if is_instance_valid(GameManager.milo):
		GameManager.milo.dash_and_attack(
			target_enemy.global_position
		)
	
	# --- d20 Hit Check Resolver ---
	var hit_roll: int = randi_range(1, 20)
	print("[Dice] Milo rolled a d20: ", hit_roll, " vs Target AC: ", target_enemy.armor_class)
	
	if hit_roll >= target_enemy.armor_class:
		print("[Battle] Hit! Applying damage.")
		var damage_amount: int = PlayerStateManager.attack_power
		target_enemy.take_damage(damage_amount)
		
		# Add the damage popup with the hit value
		target_enemy.spawn_damage_popup(str(damage_amount), Color(0.9, 0.3, 0.2))
	else:
		print("[Battle] Miss! Milo's strike failed to bypass enemy armor.")
		
		# Add the damage poput with missed
		target_enemy.spawn_damage_popup("Missed!", Color(0.6, 0.6, 0.6))
		
	_enter_state(BattleState.CHECK_WIN_LOSS)

## Puts Milo into a defensive position, mitigating damage until his next turn.
func execute_player_defend() -> void:
	if current_state != BattleState.PLAYER_TURN:
		return
		
	if UiCanvas and UiCanvas.battle_ui_menu:
		UiCanvas.battle_ui_menu.close()
		
	print("[Battle] Milo takes a defensive stance! Incoming damage will be mitigated.")
	PlayerStateManager.is_defending = true
	
	_enter_state(BattleState.CHECK_WIN_LOSS)


## Coordinates active enemy entity decision-making ONE entity at a time.
func _start_enemy_turn() -> void:
	print("[Battle] Enemies are acting... Current Index Evaluated: ", current_enemy_index)
	
	if current_state != BattleState.ENEMY_TURN:
		return

	# Guard Clause: If enemies array is empty, reset indices and alternate back
	if active_enemies.is_empty():
		current_enemy_index = 0
		_enter_state(BattleState.CHECK_WIN_LOSS)
		return
		
	# Check if all enemies in the registry have already performed an action this round
	if current_enemy_index >= active_enemies.size():
		print("[Battle] All enemies acted. Resetting index for next round.")
		current_enemy_index = 0
		# Hard-force state back to PLAYER_TURN because the round cycle has closed completely
		current_state = BattleState.ENEMY_TURN
		_enter_state(BattleState.PLAYER_TURN)
		return

	var enemy: Node = active_enemies[current_enemy_index]
	
	# Guard against instances that were freed (killed) out of turn sequence
	if not is_instance_valid(enemy):
		print("[Battle] Warning: Enemy at index ", current_enemy_index, " is dead. Skipping slot.")
		# Do not increment here because the living arrays auto-shift down inside check_rules
		_enter_state(BattleState.CHECK_WIN_LOSS)
		return

	if enemy is BattleEntity:
		var active_enemy: BattleEntity = enemy as BattleEntity
		
		# 1. TRIGGER ENEMY TURN BANNER
		if UiCanvas and UiCanvas.battle_ui_menu:
			var banner_text: String = active_enemy.entity_name + "'s Turn!"
			UiCanvas.battle_ui_menu.announce_event(banner_text)
			await get_tree().create_timer(1.8).timeout
		
		# Double check validity after the long UI await animation, just in case
		if not is_instance_valid(active_enemy):
			_enter_state(BattleState.CHECK_WIN_LOSS)
			return
			
		print("[Battle] executing action for: ", active_enemy.entity_name)
		
		# Enemy dash attack
		if is_instance_valid(GameManager.milo):
			active_enemy.dash_and_attack(
				GameManager.milo.global_position
			)

		# d20 Hit Check for Enemy against Milo's Armor Class
		var enemy_roll: int = randi_range(1, 20)
		print("[Dice] ", active_enemy.entity_name, " rolled a d20: ", enemy_roll, " vs Milo AC: ", PlayerStateManager.armor_class)
		
		if enemy_roll >= PlayerStateManager.armor_class:
			print("[Battle] Hit! Milo takes damage from ", active_enemy.entity_name)
			PlayerStateManager.take_damage(active_enemy.attack_power)
			
			# Toast de Dano no Milo
			if is_instance_valid(GameManager.milo):
				var popup = DAMAGE_POPUP_SCENE.instantiate()
				popup.text = str(active_enemy.attack_power)
				popup.modulate = Color(0.9, 0.3, 0.2)
				get_tree().current_scene.add_child(popup)
				popup.global_position = GameManager.milo.global_position + Vector2(-30, -50)
		else:
			print("[Battle] Miss! ", active_enemy.entity_name, "'s attack bounced off Milo's guard.")
			
			# Toast de Missed! no Milo
			if is_instance_valid(GameManager.milo):
				var popup = DAMAGE_POPUP_SCENE.instantiate()
				popup.text = "Missed!"
				popup.modulate = Color(0.6, 0.6, 0.6)
				get_tree().current_scene.add_child(popup)
				popup.global_position = GameManager.milo.global_position + Vector2(-30, -50)
		
		# Pacing buffer delay
		await get_tree().create_timer(1.0).timeout

	# Increment index ONLY AFTER the action has executed completely
	current_enemy_index += 1
	
	# Route immediately to check_rules to handle loop persistence
	_enter_state(BattleState.CHECK_WIN_LOSS)


## Filters operational actor listings and processes progression checks.
func _check_rules() -> void:
	print("[Battle] Checking win/loss conditions...")
	
	# 1. Check Defeat Condition using the dynamic combat-specific health pool
	if PlayerStateManager.current_battle_health <= 0:
		print("[Battle] Milo has been defeated in combat!")
		_enter_state(BattleState.DEFEAT)
		return
	
	# Filter the array to retain only valid, living enemy instances
	var living_enemies: Array[Node] = []
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			living_enemies.append(enemy)
			
	active_enemies = living_enemies
	print("[Battle] Active enemies remaining in this wave: ", active_enemies.size())
	
	# THE FIX: If ALL enemies are dead, go straight to Victory/Next Wave BEFORE evaluating turn swaps
	if active_enemies.is_empty():
		print("[Battle] All wave enemies cleared successfully!")
		current_enemy_index = 0
		
		var next_wave_available: bool = (current_wave_index + 1) < current_encounter.waves.size()
		if next_wave_available:
			_enter_state(BattleState.NEXT_WAVE)
		else:
			_enter_state(BattleState.VICTORY)
		return

	# Prevent index from overflowing if Milo killed an enemy out of order
	if current_enemy_index > active_enemies.size():
		current_enemy_index = 0
	
	# THE FIX: Alternate flow depending on who just finished acting
	if current_state == BattleState.PLAYER_TURN:
		# Milo finished attacking, pass turn execution over to the Enemy Queue phase
		_enter_state(BattleState.ENEMY_TURN)
	elif current_state == BattleState.ENEMY_TURN:
		# Individual enemy completed its execution. Let's return to the loop array
		_start_enemy_turn()


## Safely shifts wave indexing scopes forward.
func _advance_wave() -> void:
	print("[Battle] Moving to next wave...")
	current_wave_index += 1
	_spawn_current_wave()


## Finalizes room teardowns, unlocks player maps, or fires global UI screens.
func _end_battle(is_victory: bool) -> void:
	# Hide action panels immediately to completely freeze any button processing
	if UiCanvas and UiCanvas.battle_ui_menu:
		UiCanvas.battle_ui_menu.close()
		
		# Hide the battle bar directly if it exists
		if "milo_battle_bar" in UiCanvas.battle_ui_menu and UiCanvas.battle_ui_menu.milo_battle_bar:
			UiCanvas.battle_ui_menu.milo_battle_bar.hide()
			
		# Completely hide the underlying Battle UI Container
		UiCanvas.battle_ui_menu.hide()
		if UiCanvas.battle_ui_menu.has_node("ActionMenu"):
			UiCanvas.battle_ui_menu.get_node("ActionMenu").hide()
		
	if is_victory:
		# Shows the door
		if is_instance_valid(exit_door):
			exit_door.visible = true

		if UiCanvas and UiCanvas.battle_ui_menu:
			# The announcer will reveal ONLY the full-screen banner text
			UiCanvas.battle_ui_menu.announce_event("You Win!!!")

		if current_encounter and current_encounter.victory_reward_item:
			if UiCanvas:
				var drop_instance = VICTORY_DROP_SCENE.instantiate()
				UiCanvas.add_child(drop_instance)
				drop_instance.launch_drop(
					current_encounter.victory_reward_item
				)

		print("[Battle] Victory!")
	else:
		if UiCanvas and UiCanvas.battle_ui_menu:
			UiCanvas.battle_ui_menu.announce_event("Sorry, you lost!")
		print("[Battle] Defeat!")

		# Wait 2 seconds
		await get_tree().create_timer(2.0).timeout

		# Go out the battle_room
		SceneManager.go_back()
