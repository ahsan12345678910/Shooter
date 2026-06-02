extends CharacterBody2D

@export var speed: float = 500.0
@export var margin: float = 32.0


func _physics_process(_delta: float) -> void:
	var direction := _get_move_direction()
	velocity.x = direction * speed
	velocity.y = 0.0
	move_and_slide()
	_clamp_to_screen()


func _get_move_direction() -> float:
	if Input.get_touch_count() > 0:
		var touch_pos := get_viewport().get_touch_position(0)
		var half_width := get_viewport().get_visible_rect().size.x * 0.5
		return -1.0 if touch_pos.x < half_width else 1.0

	if Input.is_action_pressed("ui_left"):
		return -1.0
	if Input.is_action_pressed("ui_right"):
		return 1.0

	return 0.0


func _clamp_to_screen() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	position.x = clampf(position.x, margin, viewport_size.x - margin)
