extends Button

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		pressed.emit()
