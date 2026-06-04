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

# Milo Spawn Point
@onready var hero_spawn: Marker2D = $hero_spawn

# --- Properties & Tracking ---

## Runtime collection of valid positioning markers for enemies.
var enemy_spawns: Array[Marker2D] = []

## References to actively living enemy instances in the current wave.
var active_enemies: Array[Node] = []

## Tracks the current operational phase of the battlefield.
var current_state: BattleState = BattleState.START

## Pointer index for the active combat wave within the injected encounter data.
var current_wave_index: int = 0

## The active data architecture containing waves, music, and layout metadata.
var current_encounter: BattleEncounter

# --- Lifecycle Methods ---

func _ready() -> void:
	_ensure_markers_ready()
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
	print("[Battle] Data successfully injected by SceneManager.")
	
	_enter_state(BattleState.START)


# --- Core State Controller ---

## Orchestrates state switches and executes corresponding handler logic.
func _enter_state(new_state: BattleState) -> void:
	current_state = new_state
	
	match current_state:
		BattleState.START:
			_setup_battle()
		BattleState.PLAYER_TURN:
			_start_player_turn()
		BattleState.ENEMY_TURN:
			_start_enemy_turn()
		BattleState.CHECK_WIN_LOSS:
			_check_rules()
		BattleState.NEXT_WAVE:
			_advance_wave()
		BattleState.VICTORY:
			_end_battle(true)
		BattleState.DEFEAT:
			_end_battle(false)


# --- Private Battle Flow Handlers ---

## Guards against early data injections by initializing spawn points on demand.
func _ensure_markers_ready() -> void:
	if enemy_spawns.is_empty():
		enemy_spawns = [spawn_01, spawn_02, spawn_03]
		print("[Battle] Spawn markers registered safely: ", enemy_spawns.size())


## Handles basic spatial layout setups, asset binding, and audio pipelines.
func _setup_battle() -> void:
	print("[Battle] Setting up battlefield...")
	
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

	# Play combat music dynamically if available
	if current_encounter.battle_music:
		music_player.stream = current_encounter.battle_music
		music_player.play()

	# Instantiate Milo safely at the validated spawn marker location
	GameManager.spawn_milo(hero_spawn.global_position)

	# Populate the active wave now that the layout and hero are initialized
	_spawn_current_wave()


## Instantiates enemy scenes bound to the current wave into registered spawn positions.
func _spawn_current_wave() -> void:
	active_enemies.clear()
	
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
			
	print("[Battle] Wave ", current_wave_index + 1, " spawned with ", active_enemies.size(), " enemies.")
	_enter_state(BattleState.PLAYER_TURN)


## Pauses automation workflows and signals interface hooks to wait for player input.
func _start_player_turn() -> void:
	print("[Battle] Milo's turn! Waiting for player input...")


## Evaluates structural validity of actions taken against a targeted index slot.
func execute_player_attack(target_index: int) -> void:
	if current_state != BattleState.PLAYER_TURN:
		print("[Battle] Cannot attack! It is not Milo's turn.")
		return
		
	if target_index >= active_enemies.size() or active_enemies[target_index] == null:
		print("[Battle] Invalid enemy target!")
		return
		
	var target_enemy: Node = active_enemies[target_index]
	print("[Battle] Milo attacks enemy at slot: ", target_index)
	
	# TODO: Inject your damage calculation here, e.g.:
	# target_enemy.take_damage(PlayerStateManager.attack_power)
	
	_enter_state(BattleState.CHECK_WIN_LOSS)


## Coordinates active enemy entity decision-making arrays.
func _start_enemy_turn() -> void:
	print("[Battle] Enemies are acting...")
	# Placeholder for enemy AI loop execution.
	_enter_state(BattleState.PLAYER_TURN)


## Filters operational actor listings and processes progression checks.
func _check_rules() -> void:
	print("[Battle] Checking win/loss conditions...")
	
	# TODO: Implement Hero vitals verification check here.
	# if PlayerStateManager.current_health <= 0:
	#     _enter_state(BattleState.DEFEAT)
	#     return
	
	var living_enemies: Array[Node] = []
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			living_enemies.append(enemy)
			
	active_enemies = living_enemies
	
	if active_enemies.size() > 0:
		_enter_state(BattleState.ENEMY_TURN)
	else:
		print("[Battle] Wave cleared!")
		if current_wave_index + 1 < current_encounter.waves.size():
			_enter_state(BattleState.NEXT_WAVE)
		else:
			_enter_state(BattleState.VICTORY)


## Safely shifts wave indexing scopes forward.
func _advance_wave() -> void:
	print("[Battle] Moving to next wave...")
	current_wave_index += 1
	_spawn_current_wave()


## Finalizes room teardowns, unlocks player maps, or fires global UI screens.
func _end_battle(is_victory: bool) -> void:
	if is_victory:
		print("[Battle] Victory!")
		# TODO: Notify SceneManager to yield rewards and return to overworld.
	else:
		print("[Battle] Defeat!")
		# TODO: Handle game over screen implementation.
