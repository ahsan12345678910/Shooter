extends Control

signal shoot_requested

const SETTINGS_PATH = "user://settings.cfg"
const AUTO_FIRE_INTERVAL: float = 0.18
const SHOOT_BTN_NORMAL := preload("res://assets/ui/shoot_btn_normal_256.png")
const SHOOT_BTN_DOUBLESHOOT := preload("res://assets/ui/shoot_btn_doubleshoot_256.png")

@export var use_joystick: bool = false

var movement_direction: float = 0.0
var _auto_fire_timer: float = 0.0
var _shoot_held: bool = false

@onready var _button_row: HBoxContainer = $BottomBar/LeftControls/ButtonRow
@onready var _virtual_joystick: Control = $BottomBar/LeftControls/VirtualJoystick
@onready var _left_button: Button = $BottomBar/LeftControls/ButtonRow/LeftButton
@onready var _right_button: Button = $BottomBar/LeftControls/ButtonRow/RightButton
@onready var _shoot_button: TextureButton = $ShootButton
@onready var _joystick_toggle: CheckButton = $BottomBar/JoystickToggle

var _left_held: bool = false
var _right_held: bool = false


func _ready() -> void:
	add_to_group("mobile_controls")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_left_button.focus_mode = Control.FOCUS_NONE
	_right_button.focus_mode = Control.FOCUS_NONE
	_shoot_button.focus_mode = Control.FOCUS_NONE
	_joystick_toggle.visible = false
	_joystick_toggle.focus_mode = Control.FOCUS_NONE

	_left_button.button_down.connect(_on_left_down)
	_left_button.button_up.connect(_on_left_up)
	_right_button.button_down.connect(_on_right_down)
	_right_button.button_up.connect(_on_right_up)
	_shoot_button.button_down.connect(_on_shoot_held)
	_shoot_button.button_up.connect(_on_shoot_released)
	_virtual_joystick.value_changed.connect(_on_joystick_changed)

	GameManager.game_over.connect(_on_game_over)
	GameManager.game_continued.connect(_on_game_continued)

	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		use_joystick = bool(cfg.get_value("prefs", "joystick", false))
	_apply_control_mode()
	_update_button_direction()
	_setup_shoot_button()


func _process(delta: float) -> void:
	if GameManager.is_game_over:
		movement_direction = 0.0
		return

	if use_joystick:
		movement_direction = _virtual_joystick.output.x
	else:
		_update_button_direction()

	if _shoot_held and not GameManager.is_game_over and not GameManager.is_paused:
		_auto_fire_timer -= delta
		if _auto_fire_timer <= 0.0:
			_auto_fire_timer = AUTO_FIRE_INTERVAL
			shoot_requested.emit()


func get_movement_direction() -> float:
	return movement_direction


func set_shoot_button_state(state: String) -> void:
	match state:
		"normal":
			_shoot_button.texture_normal = SHOOT_BTN_NORMAL
			_shoot_button.modulate = Color(1, 1, 1, 1)
		"doubleshoot":
			_shoot_button.texture_normal = SHOOT_BTN_DOUBLESHOOT
			_shoot_button.modulate = Color(1, 1, 1, 1)
			_flash_button_activate()
		_:
			_shoot_button.texture_normal = SHOOT_BTN_NORMAL


func _setup_shoot_button() -> void:
	_shoot_button.texture_normal = SHOOT_BTN_NORMAL
	_shoot_button.texture_pressed = SHOOT_BTN_NORMAL
	_shoot_button.ignore_texture_size = true
	_shoot_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_shoot_button.modulate = Color(1, 1, 1, 1)
	_shoot_button.scale = Vector2.ONE
	_shoot_button.visible = true


func _flash_button_activate() -> void:
	var tween := create_tween()
	tween.tween_property(_shoot_button, "scale", Vector2(1.25, 1.25), 0.1)
	tween.tween_property(_shoot_button, "scale", Vector2(1.0, 1.0), 0.15)


func _apply_control_mode() -> void:
	_button_row.visible = not use_joystick
	_virtual_joystick.visible = use_joystick
	movement_direction = 0.0
	_left_held = false
	_right_held = false
	if _virtual_joystick.has_method("reset"):
		_virtual_joystick.reset()


func _on_left_down() -> void:
	_left_held = true
	_update_button_direction()


func _on_left_up() -> void:
	_left_held = false
	_update_button_direction()


func _on_right_down() -> void:
	_right_held = true
	_update_button_direction()


func _on_right_up() -> void:
	_right_held = false
	_update_button_direction()


func _update_button_direction() -> void:
	var direction := 0.0
	if _left_held:
		direction -= 1.0
	if _right_held:
		direction += 1.0
	movement_direction = direction


func _on_joystick_changed(_vector: Vector2) -> void:
	if use_joystick:
		movement_direction = _virtual_joystick.output.x


func _on_shoot_held() -> void:
	if GameManager.is_game_over:
		return
	_shoot_held = true
	shoot_requested.emit()
	_auto_fire_timer = AUTO_FIRE_INTERVAL
	var tween := create_tween()
	tween.tween_property(_shoot_button, "scale", Vector2(0.88, 0.88), 0.06)


func _on_shoot_released() -> void:
	_shoot_held = false
	_auto_fire_timer = 0.0
	var tween := create_tween()
	tween.tween_property(_shoot_button, "scale", Vector2(1.0, 1.0), 0.08)


func _on_game_over() -> void:
	movement_direction = 0.0
	_shoot_held = false
	_set_controls_enabled(false)


func _on_game_continued() -> void:
	_set_controls_enabled(true)


func _set_controls_enabled(enabled: bool) -> void:
	_left_button.disabled = not enabled
	_right_button.disabled = not enabled
	_shoot_button.disabled = not enabled
	_virtual_joystick.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
