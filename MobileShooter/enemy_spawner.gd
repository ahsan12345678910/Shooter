# enemy_spawner.gd
extends Node

const EnemyScene: PackedScene = preload("res://Enemy.tscn")
const BossScene: PackedScene = preload("res://Boss.tscn")

@export var spawn_margin_x: float = 48.0
@export var spawn_y: float = -40.0

var _timer: float = 0.0
var _spawn_interval: float = 2.0
var _enemies_to_spawn: int = 0
var _scout_ratio: float = 1.0
var _boss_spawned: bool = false
var _active: bool = false


func _ready() -> void:
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_continued.connect(_on_game_continued)


func _on_level_started(level_number: int) -> void:
	var data := LevelData.get_level(level_number)
	_spawn_interval = data["spawn_interval"]
	_enemies_to_spawn = data["enemy_count"]
	_scout_ratio = data["scout_ratio"]
	_boss_spawned = false
	_timer = 0.0
	_active = true

	if data["boss"]:
		_spawn_boss(data["boss_hp"])
		_boss_spawned = true
		_enemies_to_spawn = maxi(0, _enemies_to_spawn - 1)


func _on_level_completed(_level: int, _coins: int) -> void:
	_active = false
	var enemies_parent := get_parent().get_node_or_null("Enemies")
	if enemies_parent:
		for child in enemies_parent.get_children():
			child.queue_free()


func _on_game_continued() -> void:
	if not GameManager.level_active:
		return
	_active = true
	var remaining := GameManager.enemies_required_this_level - GameManager.enemies_killed_this_level
	if remaining <= 0:
		return
	var enemies_parent := get_parent().get_node_or_null("Enemies")
	var on_screen := enemies_parent.get_child_count() if enemies_parent else 0
	if _enemies_to_spawn <= 0 and on_screen == 0:
		_enemies_to_spawn = remaining
		_timer = _spawn_interval


func _process(delta: float) -> void:
	if not _active:
		return
	if GameManager.is_game_over or GameManager.is_paused:
		return
	if _enemies_to_spawn <= 0:
		return

	_timer += delta
	if _timer < _spawn_interval:
		return
	_timer = 0.0

	var wave_size := mini(3, _enemies_to_spawn)
	var count := clampi(1 + (GameManager.current_level / 5), 1, wave_size)
	count = mini(count, _enemies_to_spawn)

	for i in count:
		var type := 1 if randf() > _scout_ratio else 0
		_spawn_enemy(type, i, count)
		_enemies_to_spawn -= 1


func _spawn_enemy(type: int, index: int = 0, total: int = 1) -> void:
	var enemies_parent := get_parent().get_node_or_null("Enemies")
	if enemies_parent == null:
		return

	var vp_size := get_viewport().get_visible_rect().size
	var center_x := vp_size.x * 0.5
	var spread := 80.0
	var offset := (float(index) - (float(total) - 1.0) * 0.5) * spread
	var spawn_x := clampf(
		center_x + offset + randf_range(-28.0, 28.0),
		spawn_margin_x,
		vp_size.x - spawn_margin_x
	)

	var enemy: Area2D = EnemyScene.instantiate()
	enemy.enemy_type = type
	enemy.score_value = GameManager.get_score_per_kill()
	enemy.can_shoot = (type == 1)
	enemy.shoot_interval = 2.2 if type == 1 else 1.4
	enemies_parent.add_child(enemy)
	enemy.position = Vector2(spawn_x, spawn_y + randf_range(-16.0, 16.0))


func _spawn_boss(boss_hp: int) -> void:
	var enemies_parent := get_parent().get_node_or_null("Enemies")
	if enemies_parent == null:
		return

	var vp_size := get_viewport().get_visible_rect().size
	var boss: Area2D = BossScene.instantiate()
	enemies_parent.add_child(boss)
	boss.position = Vector2(vp_size.x * 0.5, spawn_y - 80.0)

	if boss.has_method("setup"):
		boss.setup({
			"hp": boss_hp,
			"base_speed": 70.0,
			"score_value": GameManager.get_score_per_kill() * 5,
			"is_boss": true,
			"powerup_drop_chance": 0.7,
		})

	boss.can_shoot = true
	boss.shoot_interval = 1.2
	boss.bullet_speed = 420.0
	AudioManager.play_boss_appear()
