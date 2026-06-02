extends Node2D

@onready var _score_label: Label = $UI/HUD/ScoreLabel
@onready var _high_score_label: Label = $UI/HUD/HighScoreLabel
@onready var _lives_label: Label = $UI/HUD/LivesLabel
@onready var _pause_button: Button = $UI/HUD/PauseButton
@onready var _pause_panel: Control = $UI/PausePanel
@onready var _resume_button: Button = $UI/PausePanel/CenterContainer/VBoxContainer/ResumeButton
@onready var _game_over_panel: Control = $UI/GameOverPanel
@onready var _final_score_label: Label = $UI/GameOverPanel/CenterContainer/VBoxContainer/FinalScoreLabel
@onready var _final_high_score_label: Label = $UI/GameOverPanel/CenterContainer/VBoxContainer/FinalHighScoreLabel
@onready var _restart_button: Button = $UI/GameOverPanel/CenterContainer/VBoxContainer/RestartButton


func _ready() -> void:
	_pause_button.pressed.connect(_on_pause_pressed)
	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)

	GameManager.reset_game()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.high_score_changed.connect(_on_high_score_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.paused_changed.connect(_on_paused_changed)

	_pause_panel.hide()
	_game_over_panel.hide()
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	_on_high_score_changed(GameManager.high_score)
	AudioManager.play_music()


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	_lives_label.text = "Lives: %d" % new_lives


func _on_high_score_changed(new_high_score: int) -> void:
	_high_score_label.text = "Best: %d" % new_high_score


func _on_pause_pressed() -> void:
	GameManager.toggle_pause()


func _on_resume_pressed() -> void:
	GameManager.set_paused(false)


func _on_paused_changed(is_paused: bool) -> void:
	_pause_panel.visible = is_paused
	_pause_button.visible = not is_paused


func _on_game_over() -> void:
	_final_score_label.text = "Final Score: %d" % GameManager.score
	_final_high_score_label.text = "Best: %d" % GameManager.high_score
	_game_over_panel.show()
	_pause_panel.hide()
	_pause_button.visible = false
	AudioManager.stop_music()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
