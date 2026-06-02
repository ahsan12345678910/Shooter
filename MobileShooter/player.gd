extends CharacterBody2D

const BulletScene: PackedScene = preload("res://Bullet.tscn")

@export var speed: float = 500.0
@export var margin: float = 32.0
@export var shoot_cooldown: float = 0.2
@export var tap_max_duration: float = 0.25
@export var tap_max_distance: float = 20.0
@export var bullet_spawn_offset: Vector2 = Vector2(0, -36)

var _touch_direction: float = 0.0
var _pointer_active: bool = false
var _shoot_cooldown_left: float = 0.0
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time: float = 0.0
var _touch_moved: bool = false


func _process(delta: float) -> void:
	_shoot_cooldown_left = maxf(0.0, _shoot_cooldown_left - delta)


func _physics_process(_delta: float) -> void:
	var direction := _touch_direction if _pointer_active else _get_keyboard_direction()
	velocity.x = direction * speed
	velocity.y = 0.0
	move_and_slide()
	_clamp_to_screen()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _pointer_active:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event.is_action_pressed("ui_accept"):
		_try_shoot()


func _handle_screen_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		_touch_start_pos = touch.position
		_touch_start_time = Time.get_ticks_msec() / 1000.0
		_touch_moved = false
		_pointer_active = true
		_touch_direction = _direction_from_screen_x(touch.position.x)
	else:
		_try_shoot_on_tap(touch.position)
		_pointer_active = false
		_touch_direction = 0.0


func _handle_screen_drag(drag: InputEventScreenDrag) -> void:
	_touch_moved = true
	_touch_direction = _direction_from_screen_x(drag.position.x)


func _handle_mouse_button(mouse: InputEventMouseButton) -> void:
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return

	if mouse.pressed:
		_touch_start_pos = mouse.position
		_touch_start_time = Time.get_ticks_msec() / 1000.0
		_touch_moved = false
		_pointer_active = true
		_touch_direction = _direction_from_screen_x(mouse.position.x)
	else:
		_try_shoot_on_tap(mouse.position)
		_pointer_active = false
		_touch_direction = 0.0


func _handle_mouse_motion(motion: InputEventMouseMotion) -> void:
	if motion.position.distance_to(_touch_start_pos) > tap_max_distance:
		_touch_moved = true
	_touch_direction = _direction_from_screen_x(motion.position.x)


func _try_shoot_on_tap(release_pos: Vector2) -> void:
	var duration := Time.get_ticks_msec() / 1000.0 - _touch_start_time
	var distance := release_pos.distance_to(_touch_start_pos)
	if _touch_moved or duration > tap_max_duration or distance > tap_max_distance:
		return
	_try_shoot()


func _try_shoot() -> void:
	if _shoot_cooldown_left > 0.0:
		return

	var bullet := BulletScene.instantiate()
	var bullets_parent := get_parent().get_node_or_null("Bullets")
	if bullets_parent:
		bullets_parent.add_child(bullet)
	else:
		get_parent().add_child(bullet)

	bullet.global_position = global_position + bullet_spawn_offset
	_shoot_cooldown_left = shoot_cooldown


func _direction_from_screen_x(screen_x: float) -> float:
	var half_width := get_viewport().get_visible_rect().size.x * 0.5
	return -1.0 if screen_x < half_width else 1.0


func _get_keyboard_direction() -> float:
	if Input.is_action_pressed("ui_left"):
		return -1.0
	if Input.is_action_pressed("ui_right"):
		return 1.0
	return 0.0


func _clamp_to_screen() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	position.x = clampf(position.x, margin, viewport_size.x - margin)
