extends CharacterBody2D

const BulletScene: PackedScene = preload("res://Bullet.tscn")

@export var speed: float = 500.0
@export var margin: float = 32.0
@export var shoot_cooldown: float = 0.2
@export var bullet_spawn_offset: Vector2 = Vector2(0, -36)
@export var shoot_vibrate_ms: int = 40
@export var base_bullet_speed: float = 800.0
@export var powerup_duration: float = 10.0
@export var faster_bullet_multiplier: float = 1.6
@export var double_shoot_spread: float = 24.0

var _shoot_cooldown_left: float = 0.0
var _mobile_controls: Node = null
var _bullet_speed_multiplier: float = 1.0
var _double_shoot_active: bool = false
var _faster_bullets_time: float = 0.0
var _double_shoot_time: float = 0.0


func _ready() -> void:
	add_to_group("player")
	await get_tree().process_frame
	_mobile_controls = get_tree().get_first_node_in_group("mobile_controls")
	if _mobile_controls and _mobile_controls.has_signal("shoot_requested"):
		_mobile_controls.shoot_requested.connect(shoot)


func _process(delta: float) -> void:
	_shoot_cooldown_left = maxf(0.0, _shoot_cooldown_left - delta)
	_update_powerup_timers(delta)


func _physics_process(_delta: float) -> void:
	if GameManager.is_game_over:
		return

	var direction := _get_movement_direction()
	velocity.x = direction * speed
	velocity.y = 0.0
	move_and_slide()
	_clamp_to_screen()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_game_over:
		return
	if event.is_action_pressed("ui_accept"):
		shoot()


func shoot() -> void:
	if GameManager.is_game_over or _shoot_cooldown_left > 0.0:
		return

	_spawn_bullet(bullet_spawn_offset)
	if _double_shoot_active:
		_spawn_bullet(bullet_spawn_offset + Vector2(-double_shoot_spread, 0))
		_spawn_bullet(bullet_spawn_offset + Vector2(double_shoot_spread, 0))

	_shoot_cooldown_left = shoot_cooldown
	AudioManager.play_shoot()
	_vibrate_shoot()


func collect_powerup(type: Powerup.Type) -> void:
	match type:
		Powerup.Type.EXTRA_LIFE:
			GameManager.add_life()
		Powerup.Type.FASTER_BULLETS:
			_apply_faster_bullets()
		Powerup.Type.DOUBLE_SHOOT:
			_apply_double_shoot()


func _spawn_bullet(offset: Vector2) -> void:
	var bullet := BulletScene.instantiate()
	var bullets_parent := get_parent().get_node_or_null("Bullets")
	if bullets_parent:
		bullets_parent.add_child(bullet)
	else:
		get_parent().add_child(bullet)

	bullet.global_position = global_position + offset
	bullet.speed = base_bullet_speed * _bullet_speed_multiplier


func _apply_faster_bullets() -> void:
	_bullet_speed_multiplier = faster_bullet_multiplier
	_faster_bullets_time = powerup_duration


func _apply_double_shoot() -> void:
	_double_shoot_active = true
	_double_shoot_time = powerup_duration


func _update_powerup_timers(delta: float) -> void:
	if _faster_bullets_time > 0.0:
		_faster_bullets_time -= delta
		if _faster_bullets_time <= 0.0:
			_bullet_speed_multiplier = 1.0

	if _double_shoot_time > 0.0:
		_double_shoot_time -= delta
		if _double_shoot_time <= 0.0:
			_double_shoot_active = false


func _get_movement_direction() -> float:
	if _mobile_controls and _mobile_controls.has_method("get_movement_direction"):
		var ui_direction: float = _mobile_controls.get_movement_direction()
		if ui_direction != 0.0:
			return ui_direction
	return _get_keyboard_direction()


func _get_keyboard_direction() -> float:
	if Input.is_action_pressed("ui_left"):
		return -1.0
	if Input.is_action_pressed("ui_right"):
		return 1.0
	return 0.0


func _vibrate_shoot() -> void:
	if not (OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS")):
		return
	Input.vibrate_handheld(shoot_vibrate_ms)


func _clamp_to_screen() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	position.x = clampf(position.x, margin, viewport_size.x - margin)
