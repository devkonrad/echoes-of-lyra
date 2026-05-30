extends Node2D

func _ready() -> void:
	# Espera um frame para garantir que o GameManager inicializou a estrutura
	await get_tree().process_frame

