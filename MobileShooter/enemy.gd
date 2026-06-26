extends Area2D

enum EnemyType { SCOUT, DESTROYER, BOSS }

const PowerupScene: PackedScene = preload("res://Powerup.tscn")
const EnemyBulletScene: PackedScene = preload("res://Bullet.tscn")

@export var enemy_type: EnemyType = EnemyType.SCOUT
@export var base_speed: float = 120.0
@export var margin: float = 32.0
@export var powerup_drop_chance: float = 0.25
@export var score_value: int = 1
@export var can_shoot: bool = false
@export var shoot_interval: float = 2.2
@export var bullet_speed: float = 320.0

var speed: float = 120.0
var hp: int = 1
var max_hp: int = 1
var is_boss: bool = false
var _move_time: float = 0.0
var _drift_phase: float = 0.0
var _shoot_timer: float = 0.0
var _is_dying: bool = false

static var _powerup_types: Array = [
	Powerup.Type.EXTRA_LIFE,
	Powerup.Type.FASTER_BULLETS,
	Powerup.Type.DOUBLE_SHOOT,
]

@onready var sprite: Sprite2D = $Sprite2D
@onready var _hp_label: Label = $HPLabel


func _ready() -> void:
	_drift_phase = randf() * TAU
	_setup_sprite()
	_setup_collision()
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)
	_apply_speed()
	_update_hp_display()
	_shoot_timer = shoot_interval * randf_range(0.4, 1.0)


func setup(config: Dictionary = {}) -> void:
	base_speed = config.get("base_speed", base_speed)
	hp = config.get("hp", 1)
	max_hp = hp
	score_value = config.get("score_value", 1)
	is_boss = config.get("is_boss", false)
	powerup_drop_chance = config.get("powerup_drop_chance", powerup_drop_chance)

	if is_boss:
		enemy_type = EnemyType.BOSS

	if is_node_ready():
		_setup_sprite()
		_setup_collision()
		_apply_speed()
		_update_hp_display()


func _setup_sprite() -> void:
	match enemy_type:
		EnemyType.SCOUT:
			sprite.texture = SpriteUtils.load_texture(SpriteUtils.ENEMY_SCOUT_TEXTURE)
			sprite.scale = Vector2(1, 1)
		EnemyType.DESTROYER:
			sprite.texture = SpriteUtils.load_texture(SpriteUtils.ENEMY_DEST_TEXTURE)
			sprite.scale = Vector2(1, 1)
		EnemyType.BOSS:
			sprite.texture = SpriteUtils.load_texture(SpriteUtils.BOSS_TEXTURE)
			sprite.scale = Vector2(1, 1)


func _setup_collision() -> void:
	var shape := $CollisionShape2D.shape as CircleShape2D
	match enemy_type:
		EnemyType.SCOUT:
			shape.radius = 28
		EnemyType.DESTROYER:
			shape.radius = 40
		EnemyType.BOSS:
			shape.radius = 60


func flash_damage() -> void:
	AudioManager.play_enemy_hit()
	sprite.modulate = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.08).timeout
	sprite.modulate = Color(1, 1, 1, 1)


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_paused:
		return

	if can_shoot:
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_shoot_timer = shoot_interval
			_fire_bullet()

	_move_time += delta
	position.x += sin(_move_time * 2.0 + _drift_phase) * 18.0 * delta
	position.y += speed * delta
	var rect_size := get_viewport().get_visible_rect().size

	if global_position.y >= rect_size.y + margin:
		GameManager.lose_life()
		_remove_without_kill()
		return

	if global_position.x < -margin or global_position.x > rect_size.x + margin:
		_remove_without_kill()


func _fire_bullet() -> void:
	if GameManager.is_game_over or GameManager.is_paused:
		return
	var bullets_parent := get_tree().current_scene.get_node_or_null("Bullets")
	if bullets_parent == null:
		return
	var b: Area2D = EnemyBulletScene.instantiate()
	b.is_enemy_bullet = true
	b.speed = bullet_speed * GameManager.enemy_speed_multiplier
	bullets_parent.add_child(b)
	b.global_position = global_position + Vector2(0, 36)
	AudioManager.play_shoot()


func _on_area_entered(area: Area2D) -> void:
	if _is_dying or GameManager.is_game_over or not area.is_in_group("bullets"):
		return
	if area.get("is_enemy_bullet"):
		return

	area.queue_free()
	hp -= 1
	flash_damage()
	_update_hp_display()

	if hp > 0:
		return

	_is_dying = true
	GameManager.add_score(score_value)
	if is_boss:
		AudioManager.play_level_up()
		GameManager.award_boss_kill_coins(GameManager.current_level)
	GameManager.on_enemy_killed()
	_try_drop_powerup(global_position)
	_die()


func _apply_speed() -> void:
	speed = base_speed * GameManager.enemy_speed_multiplier


func _update_hp_display() -> void:
	if enemy_type == EnemyType.BOSS or max_hp > 1:
		_hp_label.visible = true
		_hp_label.text = str(hp)
	else:
		_hp_label.visible = false


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


func _die() -> void:
	AudioManager.play_explosion()
	sprite.visible = false
	var explosion = preload("res://Explosion.tscn").instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	queue_free()


func _remove_without_kill() -> void:
	if _is_dying:
		return
	_is_dying = true
	GameManager.on_enemy_escaped()
	queue_free()
