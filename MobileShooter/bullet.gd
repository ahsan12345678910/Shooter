extends Area2D

@export var speed: float = 800.0
@export var margin: float = 32.0


func _ready() -> void:
	add_to_group("bullets")


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_paused:
		return
	position.y -= speed * delta
	if _is_off_screen():
		queue_free()


func _is_off_screen() -> bool:
	var rect := get_viewport().get_visible_rect()
	return (
		global_position.y < -margin
		or global_position.y > rect.size.y + margin
		or global_position.x < -margin
		or global_position.x > rect.size.x + margin
	)
