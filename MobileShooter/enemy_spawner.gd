extends Node

const EnemyScene: PackedScene = preload("res://Enemy.tscn")
const BossScene: PackedScene = preload("res://Boss.tscn")

@export var base_spawn_interval: float = 2.0
@export var spawn_margin_x: float = 48.0
@export var spawn_y: float = -48.0

var _timer: float = 0.0


func _ready() -> void:
	GameManager.boss_spawn_requested.connect(_spawn_boss)


func _process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_paused:
		return

	_timer += delta
	var interval := GameManager.get_spawn_interval_for_score(base_spawn_interval)
	if _timer < interval:
		return
	_timer = 0.0

	var spawn_count := GameManager.get_spawn_count_for_score()
	for i in spawn_count:
		_spawn_enemy(i, spawn_count)


func _spawn_enemy(index: int = 0, total: int = 1) -> void:
	var enemies_parent := get_parent().get_node_or_null("Enemies")
	if enemies_parent == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var center_x := viewport_size.x * 0.5
	var spread := 72.0
	var offset := (float(index) - (float(total) - 1.0) * 0.5) * spread
	var spawn_x := clampf(
		center_x + offset + randf_range(-24.0, 24.0),
		spawn_margin_x,
		viewport_size.x - spawn_margin_x
	)

	var enemy: Area2D = EnemyScene.instantiate()
	enemies_parent.add_child(enemy)
	enemy.position = Vector2(spawn_x, spawn_y + randf_range(-16.0, 16.0))


func _spawn_boss(milestone: int) -> void:
	var enemies_parent := get_parent().get_node_or_null("Enemies")
	if enemies_parent == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var spawn_x := viewport_size.x * 0.5

	var boss: Area2D = BossScene.instantiate()
	enemies_parent.add_child(boss)
	boss.position = Vector2(spawn_x, spawn_y - 80.0)
	if boss.has_method("setup"):
		boss.setup({
			"hp": GameManager.get_boss_hp_for_milestone(milestone),
			"base_speed": 75.0,
			"score_value": 15,
			"is_boss": true,
			"powerup_drop_chance": 0.6,
		})
