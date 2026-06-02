extends Area2D

@export var speed: float = 120.0
@export var margin: float = 32.0


func _ready() -> void:
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position.y += speed * delta
	if _is_off_screen():
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("bullets"):
		return
	GameManager.add_score(1)
	area.queue_free()
	queue_free()


func _is_off_screen() -> bool:
	var rect := get_viewport().get_visible_rect()
	return (
		global_position.y < -margin
		or global_position.y > rect.size.y + margin
		or global_position.x < -margin
		or global_position.x > rect.size.x + margin
	)
