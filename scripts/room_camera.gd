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

var player: CharacterBody2D = null

func _ready() -> void:
	print("Loading main camera...")

func _process(_delta: float) -> void:
	# Test player instance
	if not is_instance_valid(player) and is_instance_valid(GameManager.milo):
		player = GameManager.milo # Hook into your global manager dynamically

		# Recalculate grid coordinates based on actual Milo position ---
		_sync_grid_to_player_position()
		_update_camera_position(false)
		
	if is_instance_valid(player) and not is_transitioning:
		_check_player_bounds()

# Checks if the player has crossed the current screen boundaries
func _check_player_bounds() -> void:
	if not is_instance_valid(GameManager.milo):
		return
	
	var player_pos: Vector2 = GameManager.milo.global_position
	
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
		if is_instance_valid(player): player.set_physics_process(false)
		
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_QUART)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "global_position", target_position, 0.7) # 0.7 seconds transition
		tween.tween_callback(func(): 
			is_transitioning = false
			if is_instance_valid(player): player.set_physics_process(true)
		)
	else:
		global_position = target_position

# Finds the correct quadrant coordinates based on Milo's physics location ---
func _sync_grid_to_player_position() -> void:
	if not is_instance_valid(player):
		return

	# Using floor division to translate pixels into discrete grid steps
	current_grid_x = int(floor(player.global_position.x / SCREEN_WIDTH))

	# Since current_grid_y uses 1-indexed notation (1-8), we add 1 after the division
	current_grid_y = int(floor(player.global_position.y / SCREEN_HEIGHT)) + 1

	# Clamp numbers to keep them strictly within bounds of an 8x8 matrix (0-7 indexing)
	current_grid_x = clampi(current_grid_x, 0, 7)
	current_grid_y = clampi(current_grid_y, 1, 8)

	_print_current_quadrant()

# Debug print to show current quadrant in Zelda notation (e.g., E4)
func _print_current_quadrant() -> void:
	var col_letter: String = COLUMNS[clampi(current_grid_x, 0, 7)]
	print("Camera: Matrix locked on Quadrant [", col_letter, current_grid_y, "]")
