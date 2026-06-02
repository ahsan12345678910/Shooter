extends Node

const EnemyScene: PackedScene = preload("res://Enemy.tscn")

@export var spawn_interval: float = 2.0
@export var spawn_margin_x: float = 48.0
@export var spawn_y: float = -48.0

var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer += delta
	if _timer < spawn_interval:
		return
	_timer = 0.0
	_spawn_enemy()


func _spawn_enemy() -> void:
	var enemies_parent := get_parent().get_node_or_null("Enemies")
	if enemies_parent == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var spawn_x := randf_range(spawn_margin_x, viewport_size.x - spawn_margin_x)

	var enemy := EnemyScene.instantiate()
	enemies_parent.add_child(enemy)
	enemy.position = Vector2(spawn_x, spawn_y)
