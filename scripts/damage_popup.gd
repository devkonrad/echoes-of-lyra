extends Label

func _ready() -> void:
	pivot_offset = size / 2
	
	var tween: Tween = create_tween().set_parallel(true)
	
	# Text up
	tween.tween_property(self, "position:y", position.y - 15, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Text fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.5) # Começa o fade depois de 0.2s
	
	# Text size effects
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Waiting for paralels animations
	var chain_tween = create_tween()
	chain_tween.tween_interval(1.0) # wait a second
	chain_tween.tween_callback(queue_free)
