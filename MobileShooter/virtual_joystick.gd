extends Control

signal value_changed(vector: Vector2)

@export var max_distance: float = 72.0
@export var deadzone: float = 0.12

@onready var _knob: Control = $Base/Knob

var output: Vector2 = Vector2.ZERO

var _center: Vector2 = Vector2.ZERO
var _pointer_active: bool = false


func _ready() -> void:
	await get_tree().process_frame
	_center = $Base.size * 0.5
	_reset_knob()


func reset() -> void:
	_release()


func _gui_input(event: InputEvent) -> void:
	if GameManager.is_game_over:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		_pointer_active = true
		_update_from_local_pos(touch.position)
	else:
		_release()


func _handle_drag(drag: InputEventScreenDrag) -> void:
	if _pointer_active:
		_update_from_local_pos(drag.position)


func _handle_mouse_button(mouse: InputEventMouseButton) -> void:
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.pressed:
		_pointer_active = true
		_update_from_local_pos(mouse.position)
	else:
		_release()


func _handle_mouse_motion(motion: InputEventMouseMotion) -> void:
	if _pointer_active:
		_update_from_local_pos(motion.position)


func _update_from_local_pos(local_pos: Vector2) -> void:
	var offset := local_pos - _center
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance

	_knob.position = _center + offset - _knob.size * 0.5
	output = offset / max_distance if max_distance > 0.0 else Vector2.ZERO

	if output.length() < deadzone:
		output = Vector2.ZERO
	else:
		var strength := (output.length() - deadzone) / (1.0 - deadzone)
		output = output.normalized() * strength

	value_changed.emit(output)


func _release() -> void:
	_pointer_active = false
	output = Vector2.ZERO
	_reset_knob()
	value_changed.emit(output)


func _reset_knob() -> void:
	_knob.position = _center - _knob.size * 0.5
