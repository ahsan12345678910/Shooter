class_name Powerup
extends Area2D

enum Type { EXTRA_LIFE, FASTER_BULLETS, DOUBLE_SHOOT }

const TYPE_COLORS: Dictionary = {
	Type.EXTRA_LIFE: Color(0.35, 0.95, 0.45),
	Type.FASTER_BULLETS: Color(1.0, 0.9, 0.25),
	Type.DOUBLE_SHOOT: Color(0.45, 0.85, 1.0),
}

const TYPE_LABELS: Dictionary = {
	Type.EXTRA_LIFE: "+1",
	Type.FASTER_BULLETS: "FAST",
	Type.DOUBLE_SHOOT: "2X",
}

@export var fall_speed: float = 90.0
@export var margin: float = 32.0

var powerup_type: Type = Type.EXTRA_LIFE

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _label: Label = $Label


func _ready() -> void:
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)
	_apply_visuals()


func setup(type: Type) -> void:
	powerup_type = type
	if is_node_ready():
		_apply_visuals()


func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	position.y += fall_speed * delta
	var rect_size := get_viewport().get_visible_rect().size
	if global_position.y > rect_size.y + margin:
		queue_free()


func _apply_visuals() -> void:
	_sprite.modulate = TYPE_COLORS.get(powerup_type, Color.WHITE)
	_label.text = TYPE_LABELS.get(powerup_type, "?")


func _on_body_entered(body: Node2D) -> void:
	if GameManager.is_game_over or not body.is_in_group("player"):
		return
	if body.has_method("collect_powerup"):
		body.collect_powerup(powerup_type)
	AudioManager.play_powerup_collect()
	queue_free()
