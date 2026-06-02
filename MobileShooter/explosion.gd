extends Node2D

@onready var _particles: CPUParticles2D = $CPUParticles2D
@onready var _flash: Sprite2D = $Flash


func _ready() -> void:
	_particles.emitting = true
	_flash.scale = Vector2(0.4, 0.4)
	_flash.modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash, "scale", Vector2(2.2, 2.2), 0.35)
	tween.tween_property(_flash, "modulate:a", 0.0, 0.35)

	await get_tree().create_timer(0.45).timeout
	queue_free()


static func spawn(parent: Node2D, world_position: Vector2) -> void:
	if parent == null:
		return
	var explosion: Node2D = preload("res://Explosion.tscn").instantiate()
	parent.add_child(explosion)
	explosion.global_position = world_position
