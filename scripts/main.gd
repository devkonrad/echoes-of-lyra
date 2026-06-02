extends Node2D

func _ready() -> void:
	_boot_game()

func _process(delta: float) -> void:
	# Evita dar print se os caminhos ainda estiverem vazios no primeiro frame
	if SceneManager.current_scene_path != "":
		#print("PREVIOUS SCENE >> ", SceneManager.previous_scene_path)
		#print("CURRENT SCENE >> ", SceneManager.current_scene_path)
		pass

func _boot_game() -> void:
	print("Main: Booting game systems...")
	GameManager.start_game(self)
