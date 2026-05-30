extends Camera2D

# --- Resolution Constants ---
const SCREEN_WIDTH: float = 480.0
const SCREEN_HEIGHT: float = 270.0

# --- Grid Configuration (8x8) ---
const COLUMNS: String = "ABCDEFGH"

# --- State ---
var current_grid_x: int = 4 # Column E (0=A, 1=B, 2=C, 3=D, 4=E...)
var current_grid_y: int = 4 # Line 4   (1-indexed mapping to 0-7, so 4 is index 3)

var target_position: Vector2 = Vector2.ZERO
var is_transitioning: bool = false

@export var player_path: NodePath
var player: CharacterBody2D = null

func _ready() -> void:
	# If player path is set, fetch the reference
	if player_path:
		player = get_node(player_path) as CharacterBody2D
	
	# Initial room positioning (e.g., E4)
	# Converting E (index 4) and 4 (index 3) to pixels
	_update_camera_position(false)

func _process(_delta: float) -> void:
	if not player and GameManager.milo:
		player = GameManager.milo # Hook into your global manager dynamically
		_update_camera_position(false)
		
	if player and not is_transitioning:
		_check_player_bounds()

# Checks if the player has crossed the current screen boundaries
func _check_player_bounds() -> void:
	var player_pos: Vector2 = player.global_position
	
	# Calculate current screen bounds based on active grid quadrant
	var min_x: float = current_grid_x * SCREEN_WIDTH
	var max_x: float = min_x + SCREEN_WIDTH
	var min_y: float = (current_grid_y - 1) * SCREEN_HEIGHT
	var max_y: float = min_y + SCREEN_HEIGHT
	
	var changed: bool = false
	
	# Cross Right Border -> Move East
	if player_pos.x > max_x:
		current_grid_x += 1
		player.global_position.x += 16.0 # Nudge player into the next screen
		changed = true
	# Cross Left Border -> Move West
	elif player_pos.x < min_x:
		current_grid_x -= 1
		player.global_position.x -= 16.0
		changed = true
		
	# Cross Bottom Border -> Move South
	if player_pos.y > max_y:
		current_grid_y += 1
		player.global_position.y += 16.0
		changed = true
	# Cross Top Border -> Move North
	elif player_pos.y < min_y:
		current_grid_y -= 1
		player.global_position.y -= 16.0
		changed = true
		
	if changed:
		_print_current_quadrant()
		_update_camera_position(true)

# Updates camera target position and handles the smooth slide transition
func _update_camera_position(smooth: bool) -> void:
	# Center of the screen is (Grid_Index * Size) + Half_Size
	var target_x: float = (current_grid_x * SCREEN_WIDTH) + (SCREEN_WIDTH / 2.0)
	var target_y: float = ((current_grid_y - 1) * SCREEN_HEIGHT) + (SCREEN_HEIGHT / 2.0)
	target_position = Vector2(target_x, target_y)
	
	if smooth:
		is_transitioning = true
		# Disable player movement during screen transition if desired
		if player: player.set_physics_process(false)
		
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_QUART)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "global_position", target_position, 0.7) # 0.7 seconds transition
		tween.tween_callback(func(): 
			is_transitioning = false
			if player: player.set_physics_process(true)
		)
	else:
		global_position = target_position

# Debug print to show current quadrant in Zelda notation (e.g., E4)
func _print_current_quadrant() -> void:
	var col_letter: String = COLUMNS[clampi(current_grid_x, 0, 7)]
	print("Camera: Moved to Quadrant [", col_letter, current_grid_y, "]")
