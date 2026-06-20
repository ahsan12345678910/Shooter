# main_menu.gd
extends Node2D

@onready var _start_btn: Button = $UI/VBox/StartButton
@onready var _shop_btn: Button = $UI/VBox/ShopButton
@onready var _settings_btn: Button = $UI/VBox/SettingsButton
@onready var _high_score_label: Label = $UI/VBox/HighScoreLabel
@onready var _coin_label_menu: Label = $UI/VBox/MenuCoinLabel
@onready var _privacy_label: Label = $UI/VBox/PrivacyLabel


func _ready() -> void:
	_high_score_label.text = "Best: %d" % GameManager.high_score
	_coin_label_menu.text = "🪙 %d" % GameManager.coins
	GameManager.coins_changed.connect(func(c): _coin_label_menu.text = "🪙 %d" % c)
	_start_btn.pressed.connect(_on_start)
	_shop_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Shop.tscn"))
	_settings_btn.pressed.connect(_on_settings)
	_privacy_label.gui_input.connect(_on_privacy_input)
	_privacy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	AudioManager.play_music()


func _on_start() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")


func _on_privacy_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		OS.shell_open("https://YOUR-PRIVACY-POLICY-URL.com")
