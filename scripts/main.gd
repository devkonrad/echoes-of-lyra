extends Node2D

func _ready() -> void:
	_boot_game()

func _process(delta: float) -> void:
	pass	

func _boot_game() -> void:
	print("Main: Booting game systems...")
	GameManager.start_game(self)
