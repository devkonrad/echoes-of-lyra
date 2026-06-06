extends CanvasLayer

@onready var inventory_ui: Control = $InventoryUI
## Reference to our modular battle action menu instanced in the canvas
@onready var battle_ui_menu: BattleUiMenu = $BattleUiMenu

# --- HUD Node References ---
@onready var heart_grid: GridContainer = $HUD/TopLeftContainer/HeartGrid
@onready var magic_bar: TextureProgressBar = $HUD/TopRightContainer/MagicBarContainer/MagicBar
@onready var rupee_label: Label = $HUD/TopRightContainer/CountersContainer/Margins/CoinCounter/Label
@onready var key_label: Label = $HUD/TopRightContainer/CountersContainer/Margins/KeyCounter/Label
@onready var item_icon: TextureRect = $HUD/ActiveItemContainer/ItemIcon

# --- Preloaded Textures for Hearts (Assuming 16x16 pixel sprites) ---
const HEART_FULL: Texture2D = preload("res://ui/heart_full.png")
const HEART_HALF: Texture2D = preload("res://ui/heart_half.png")
const HEART_EMPTY: Texture2D = preload("res://ui/heart_empty.png")

func _ready() -> void:
	# Connecting global state signals
	PlayerStateManager.health_changed.connect(_on_milo_health_changed)
	PlayerStateManager.magic_changed.connect(_on_milo_magic_changed)
	PlayerStateManager.gold_changed.connect(_on_gold_amount_changed)
	
	# Initial UI Sync
	_on_milo_health_changed(PlayerStateManager.current_health, PlayerStateManager.max_health)
	_on_milo_magic_changed(PlayerStateManager.current_magic, PlayerStateManager.max_magic)
	_on_gold_amount_changed(PlayerStateManager.gold)

func _input(event: InputEvent) -> void:
	# Block opening inventory if the battle menu is active/visible
	if battle_ui_menu.visible:
		return
		
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui.toggle()

# --- Signal Callbacks ---

func _on_milo_health_changed(current_health: int, max_health: int) -> void:
	# Clear previous hearts
	for child in heart_grid.get_children():
		child.queue_free()
	
	# Zelda classic: 1 heart container = 2 health points (HP)
	var total_hearts: int = max_health / 2
	
	for i in range(total_hearts):
		var heart: TextureRect = TextureRect.new()
		heart.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		
		# Determine if this specific container is full, half, or empty
		var heart_index_hp: int = (i + 1) * 2
		
		if current_health >= heart_index_hp:
			heart.texture = HEART_FULL
		elif current_health == heart_index_hp - 1:
			heart.texture = HEART_HALF
		else:
			heart.texture = HEART_EMPTY
			
		heart_grid.add_child(heart)


func _on_milo_magic_changed(current_magic: int, max_magic: int) -> void:
	# TextureProgressBar handles min/max values beautifully natively
	magic_bar.max_value = max_magic
	magic_bar.value = current_magic


func _on_gold_amount_changed(total_gold: int) -> void:
	rupee_label.text = str(total_gold).pad_zeros(3)


# Call this method whenever Milo changes his equipped item in the inventory
func update_active_item(item_texture: Texture2D) -> void:
	if item_texture:
		item_icon.texture = item_texture
		item_icon.visible = true
	else:
		item_icon.visible = false
