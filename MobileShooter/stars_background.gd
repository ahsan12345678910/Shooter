extends Node2D

@export var star_count: int = 90
@export var base_speed: float = 45.0
@export var background_color: Color = Color(0.04, 0.06, 0.11, 1.0)

var _stars: Array[Dictionary] = []


func _ready() -> void:
	_seed_stars()


func _seed_stars() -> void:
	_stars.clear()
	var size := get_viewport().get_visible_rect().size
	for i in star_count:
		_stars.append({
			"pos": Vector2(randf() * size.x, randf() * size.y),
			"speed": base_speed * randf_range(0.45, 1.35),
			"radius": randf_range(1.0, 2.8),
			"alpha": randf_range(0.25, 0.85),
		})


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	var size := get_viewport().get_visible_rect().size
	for star in _stars:
		star["pos"].y += star["speed"] * delta
		if star["pos"].y > size.y + 4.0:
			star["pos"].y = -4.0
			star["pos"].x = randf() * size.x

	queue_redraw()


func _draw() -> void:
	var size := get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), background_color)

	for star in _stars:
		var color := Color(1.0, 1.0, 1.0, star["alpha"])
		draw_circle(star["pos"], star["radius"], color)
