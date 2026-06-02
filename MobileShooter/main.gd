extends Node2D

@onready var _score_label: Label = $UI/HUD/ScoreLabel
@onready var _lives_label: Label = $UI/HUD/LivesLabel
@onready var _game_over_panel: Control = $UI/GameOverPanel
@onready var _final_score_label: Label = $UI/GameOverPanel/CenterContainer/VBoxContainer/FinalScoreLabel
@onready var _restart_button: Button = $UI/GameOverPanel/CenterContainer/VBoxContainer/RestartButton


func _ready() -> void:
	GameManager.reset_game()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.game_over.connect(_on_game_over)
	_restart_button.pressed.connect(_on_restart_pressed)

	_game_over_panel.hide()
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	AudioManager.play_music()


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	_lives_label.text = "Lives: %d" % new_lives


func _on_game_over() -> void:
	_final_score_label.text = "Final Score: %d" % GameManager.score
	_game_over_panel.show()
	AudioManager.stop_music()


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
