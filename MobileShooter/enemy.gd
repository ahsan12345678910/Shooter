extends Area2D

@export var speed: float = 120.0
@export var margin: float = 32.0


func _ready() -> void:
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	position.y += speed * delta
	var rect_size := get_viewport().get_visible_rect().size

	if global_position.y >= rect_size.y + margin:
		GameManager.lose_life()
		queue_free()
		return

	if global_position.y < -margin or global_position.x < -margin or global_position.x > rect_size.x + margin:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if GameManager.is_game_over or not area.is_in_group("bullets"):
		return
	GameManager.add_score(1)
	area.queue_free()
	queue_free()
