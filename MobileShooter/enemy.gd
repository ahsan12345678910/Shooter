extends Area2D

const PowerupScene: PackedScene = preload("res://Powerup.tscn")

@export var base_speed: float = 120.0
@export var margin: float = 32.0
@export var powerup_drop_chance: float = 0.25
@export var score_value: int = 1

var speed: float = 120.0
var hp: int = 1
var max_hp: int = 1
var is_boss: bool = false

static var _powerup_types: Array = [
	Powerup.Type.EXTRA_LIFE,
	Powerup.Type.FASTER_BULLETS,
	Powerup.Type.DOUBLE_SHOOT,
]

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hp_label: Label = $HPLabel


func _ready() -> void:
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
		_sprite.scale = Vector2(1.6, 1.6)
		_sprite.modulate = Color(1.0, 0.45, 0.45)
		if is_node_ready():
			_update_hp_display()
	else:
		_sprite.scale = Vector2.ONE
		_sprite.modulate = Color.WHITE

	if is_node_ready():
		_apply_speed()
		_update_hp_display()


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_paused:
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
	_sprite.modulate = Color(1.5, 1.5, 1.5) if not is_boss else Color(1.2, 0.6, 0.6)
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(self):
		_sprite.modulate = Color(1.0, 0.45, 0.45) if is_boss else Color.WHITE


func _update_hp_display() -> void:
	if is_boss or max_hp > 1:
		_hp_label.visible = true
		_hp_label.text = str(hp)
	else:
		_hp_label.visible = false


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
