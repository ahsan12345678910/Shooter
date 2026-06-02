extends Control

signal shoot_requested

@export var use_joystick: bool = false

var movement_direction: float = 0.0

@onready var _button_row: HBoxContainer = $BottomBar/LeftControls/ButtonRow
@onready var _virtual_joystick: Control = $BottomBar/LeftControls/VirtualJoystick
@onready var _left_button: Button = $BottomBar/LeftControls/ButtonRow/LeftButton
@onready var _right_button: Button = $BottomBar/LeftControls/ButtonRow/RightButton
@onready var _shoot_button: Button = $BottomBar/ShootButton
@onready var _joystick_toggle: CheckButton = $BottomBar/JoystickToggle

var _left_held: bool = false
var _right_held: bool = false


func _ready() -> void:
	add_to_group("mobile_controls")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_left_button.focus_mode = Control.FOCUS_NONE
	_right_button.focus_mode = Control.FOCUS_NONE
	_shoot_button.focus_mode = Control.FOCUS_NONE
	_joystick_toggle.focus_mode = Control.FOCUS_NONE

	_left_button.button_down.connect(_on_left_down)
	_left_button.button_up.connect(_on_left_up)
	_right_button.button_down.connect(_on_right_down)
	_right_button.button_up.connect(_on_right_up)
	_shoot_button.button_down.connect(_on_shoot_pressed)
	_virtual_joystick.value_changed.connect(_on_joystick_changed)
	_joystick_toggle.toggled.connect(_on_joystick_toggled)

	GameManager.game_over.connect(_on_game_over)

	_joystick_toggle.button_pressed = use_joystick
	_apply_control_mode()
	_update_button_direction()


func _process(_delta: float) -> void:
	if GameManager.is_game_over:
		movement_direction = 0.0
		return

	if use_joystick:
		movement_direction = _virtual_joystick.output.x
	else:
		_update_button_direction()


func get_movement_direction() -> float:
	return movement_direction


func _apply_control_mode() -> void:
	_button_row.visible = not use_joystick
	_virtual_joystick.visible = use_joystick
	movement_direction = 0.0
	_left_held = false
	_right_held = false
	if _virtual_joystick.has_method("reset"):
		_virtual_joystick.reset()


func _on_joystick_toggled(enabled: bool) -> void:
	use_joystick = enabled
	_apply_control_mode()


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


func _on_shoot_pressed() -> void:
	if GameManager.is_game_over:
		return
	shoot_requested.emit()


func _on_game_over() -> void:
	movement_direction = 0.0
	_set_controls_enabled(false)


func _set_controls_enabled(enabled: bool) -> void:
	_left_button.disabled = not enabled
	_right_button.disabled = not enabled
	_shoot_button.disabled = not enabled
	_joystick_toggle.disabled = not enabled
	_virtual_joystick.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
