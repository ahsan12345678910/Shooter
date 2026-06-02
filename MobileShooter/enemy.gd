extends Area2D

const PowerupScene: PackedScene = preload("res://Powerup.tscn")

@export var speed: float = 120.0
@export var margin: float = 32.0
@export var powerup_drop_chance: float = 0.25

static var _powerup_types: Array = [
	Powerup.Type.EXTRA_LIFE,
	Powerup.Type.FASTER_BULLETS,
	Powerup.Type.DOUBLE_SHOOT,
]


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

	var death_position := global_position
	GameManager.add_score(1)
	area.queue_free()
	_spawn_explosion(death_position)
	_try_drop_powerup(death_position)
	queue_free()


func _spawn_explosion(world_position: Vector2) -> void:
	var effects_parent := get_tree().current_scene.get_node_or_null("Effects")
	if effects_parent:
		Explosion.spawn(effects_parent, world_position)


func _try_drop_powerup(at_position: Vector2) -> void:
	if randf() > powerup_drop_chance:
		return

	var powerups_parent := get_tree().current_scene.get_node_or_null("Powerups")
	if powerups_parent == null:
		return

	var powerup: Powerup = PowerupScene.instantiate()
	powerups_parent.add_child(powerup)
	powerup.global_position = at_position
	powerup.setup(_powerup_types.pick_random())
