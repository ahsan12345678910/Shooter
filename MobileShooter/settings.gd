# settings.gd
extends Node2D

@onready var _music_slider: HSlider = $UI/VBox/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $UI/VBox/SFXRow/SFXSlider
@onready var _haptics_check: CheckButton = $UI/VBox/HapticsCheck
@onready var _joystick_check: CheckButton = $UI/VBox/JoystickCheck
@onready var _back_btn: Button = $UI/VBox/BackButton

const SETTINGS_PATH = "user://settings.cfg"


func _ready() -> void:
	_music_slider.value = AudioManager.get_music_linear()
	_sfx_slider.value = AudioManager.get_sfx_linear()
	_haptics_check.button_pressed = _load_bool("haptics", true)
	_joystick_check.button_pressed = _load_bool("joystick", false)

	_music_slider.value_changed.connect(func(v): AudioManager.set_music_volume(v))
	_sfx_slider.value_changed.connect(func(v): AudioManager.set_sfx_volume(v))
	_haptics_check.toggled.connect(func(v): _save_bool("haptics", v))
	_joystick_check.toggled.connect(func(v): _save_bool("joystick", v))
	_back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://MainMenu.tscn"))


func _load_bool(key: String, default: bool) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return default
	return bool(cfg.get_value("prefs", key, default))


func _save_bool(key: String, value: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("prefs", key, value)
	cfg.save(SETTINGS_PATH)
