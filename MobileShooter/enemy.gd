extends Area2D

const PowerupScene: PackedScene = preload("res://Powerup.tscn")
const ExplosionScript = preload("res://explosion.gd")

@export var base_speed: float = 120.0
@export var margin: float = 32.0
@export var powerup_drop_chance: float = 0.25
@export var score_value: int = 1

var speed: float = 120.0
var hp: int = 1
var max_hp: int = 1
var is_boss: bool = false
var _move_time: float = 0.0
var _drift_phase: float = 0.0

static var _powerup_types: Array = [
	Powerup.Type.EXTRA_LIFE,
	Powerup.Type.FASTER_BULLETS,
	Powerup.Type.DOUBLE_SHOOT,
]

@onready var _hp_label: Label = $HPLabel

@export var body_color: Color = Color(0.95, 0.32, 0.38, 1.0)
@export var body_size: Vector2 = Vector2(48.0, 48.0)


func _ready() -> void:
	_drift_phase = randf() * TAU
	z_index = 1
	_apply_visual_style()
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)
	GameManager.difficulty_changed.connect(_on_difficulty_changed)
	_apply_speed()
	_update_hp_display()


func setup(config: Dictionary = {}) -> void:
	base_speed = config.get("base_speed", base_speed)
	hp = config.get("hp", 1)
	max_hp = hp
	score_value = config.get("score_value", 1)
	is_boss = config.get("is_boss", false)
	powerup_drop_chance = config.get("powerup_drop_chance", powerup_drop_chance)

	if is_boss:
		body_size = Vector2(72.0, 72.0)
		body_color = Color(1.0, 0.45, 0.45, 1.0)
		if is_node_ready():
			_apply_visual_style()
			_update_hp_display()
	else:
		body_size = Vector2(48.0, 48.0)
		body_color = Color(0.95, 0.32, 0.38, 1.0)

	if is_node_ready():
		_apply_visual_style()
		_apply_speed()
		_update_hp_display()


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_paused:
		return

	_move_time += delta
	position.x += sin(_move_time * 2.0 + _drift_phase) * 18.0 * delta
	position.y += speed * delta
	queue_redraw()
	var rect_size := get_viewport().get_visible_rect().size

	if global_position.y >= rect_size.y + margin:
		GameManager.lose_life()
		queue_free()
		return

	if global_position.x < -margin or global_position.x > rect_size.x + margin:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if GameManager.is_game_over or not area.is_in_group("bullets"):
		return

	area.queue_free()
	hp -= 1
	_flash_hit()
	_update_hp_display()

	if hp > 0:
		return

	var death_position := global_position
	GameManager.add_score(score_value)
	_spawn_explosion(death_position)
	_try_drop_powerup(death_position)
	queue_free()


func _on_difficulty_changed(_multiplier: float) -> void:
	_apply_speed()


func _apply_speed() -> void:
	speed = base_speed * GameManager.enemy_speed_multiplier


func _flash_hit() -> void:
	var flash_color := Color(1.0, 0.95, 0.7) if not is_boss else Color(1.0, 0.75, 0.75)
	body_color = flash_color
	queue_redraw()
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(self):
		_apply_visual_style()


func _update_hp_display() -> void:
	if is_boss or max_hp > 1:
		_hp_label.visible = true
		_hp_label.text = str(hp)
	else:
		_hp_label.visible = false


func _spawn_explosion(world_position: Vector2) -> void:
	var effects_parent := get_tree().current_scene.get_node_or_null("Effects")
	if effects_parent:
		ExplosionScript.spawn(effects_parent, world_position)


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


func _apply_visual_style() -> void:
	if is_boss:
		body_color = Color(1.0, 0.45, 0.45, 1.0)
		body_size = Vector2(72.0, 72.0)
	else:
		body_color = Color(0.95, 0.32, 0.38, 1.0)
		body_size = Vector2(48.0, 48.0)
	queue_redraw()


func _draw() -> void:
	var half := body_size * 0.5
	var points := PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, -half.y * 0.25),
		Vector2(half.x * 0.75, half.y),
		Vector2(-half.x * 0.75, half.y),
		Vector2(-half.x, -half.y * 0.25),
	])
	draw_colored_polygon(points, body_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1.0, 1.0, 1.0, 0.35), 2.0)
