extends Node2D

@onready var _score_label: Label = $UI/HUD/ScoreLabel
@onready var _high_score_label: Label = $UI/HUD/HighScoreLabel
@onready var _lives_label: Label = $UI/HUD/LivesLabel
@onready var _hud_level_label: Label = $UI/HUD/LevelLabel
@onready var _coin_label: Label = $UI/HUD/CoinLabel
@onready var _progress_bar: ProgressBar = $UI/HUD/ProgressBar
@onready var _pause_button: Button = $UI/HUD/PauseButton
@onready var _pause_panel: Control = $UI/PausePanel
@onready var _resume_button: Button = $UI/PausePanel/CenterContainer/VBoxContainer/ResumeButton
@onready var _level_complete_panel: Control = $UI/LevelCompletePanel
@onready var _level_label_panel: Label = $UI/LevelCompletePanel/CenterContainer/VBoxContainer/LevelLabel
@onready var _coins_earned_label: Label = $UI/LevelCompletePanel/CenterContainer/VBoxContainer/CoinsEarnedLabel
@onready var _next_button: Button = $UI/LevelCompletePanel/CenterContainer/VBoxContainer/NextButton
@onready var _main_menu_button: Button = $UI/LevelCompletePanel/CenterContainer/VBoxContainer/MainMenuButton
@onready var _game_over_panel: Control = $UI/GameOverPanel
@onready var _final_score_label: Label = $UI/GameOverPanel/CenterContainer/VBoxContainer/FinalScoreLabel
@onready var _final_high_score_label: Label = $UI/GameOverPanel/CenterContainer/VBoxContainer/FinalHighScoreLabel
@onready var _continue_btn: Button = $UI/GameOverPanel/CenterContainer/VBoxContainer/ContinueButton
@onready var _share_button: Button = $UI/GameOverPanel/CenterContainer/VBoxContainer/ShareButton
@onready var _restart_button: Button = $UI/GameOverPanel/CenterContainer/VBoxContainer/RestartButton
@onready var _mobile_controls: Control = $UI/MobileControls

var _continue_used: bool = false


func _ready() -> void:
	_pause_button.pressed.connect(_on_pause_pressed)
	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_next_button.pressed.connect(_on_next_level_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_share_button.pressed.connect(_on_share_pressed)

	GameManager.reset_game()
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.high_score_changed.connect(_on_high_score_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.paused_changed.connect(_on_paused_changed)
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.level_progress_changed.connect(_on_level_progress_changed)
	GameManager.game_completed.connect(_on_game_completed)
	GameManager.coins_changed.connect(func(c): _coin_label.text = "🪙 %d" % c)
	GameManager.rate_prompt_requested.connect(_on_rate_prompt)

	_pause_panel.hide()
	_game_over_panel.hide()
	_level_complete_panel.hide()
	_share_button.hide()
	_continue_btn.hide()
	_on_score_changed(GameManager.score)
	_on_lives_changed(GameManager.lives)
	_on_high_score_changed(GameManager.high_score)
	_coin_label.text = "🪙 %d" % GameManager.coins

	GameManager.start_level(1)
	AudioManager.play_music()


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	_lives_label.text = "Lives: %d" % new_lives


func _on_high_score_changed(new_high_score: int) -> void:
	_high_score_label.text = "Best: %d" % new_high_score


func _on_level_started(level_number: int) -> void:
	_hud_level_label.text = "Lv %d" % level_number
	_level_complete_panel.hide()
	_progress_bar.value = 0
	_mobile_controls.mouse_filter = Control.MOUSE_FILTER_PASS


func _on_level_progress_changed(killed: int, required: int) -> void:
	if required > 0:
		_progress_bar.value = (float(killed) / float(required)) * 100.0


func _on_level_completed(level_number: int, coins_reward: int) -> void:
	GameManager.set_paused(true)
	_level_label_panel.text = "Level %d Complete!" % level_number
	_coins_earned_label.text = "🪙 +%d" % coins_reward

	if level_number >= LevelData.MAX_LEVEL:
		_next_button.text = "Play Again"
	else:
		_next_button.text = "Next Level →"

	_level_complete_panel.show()
	_pause_button.visible = false
	_mobile_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_next_level_pressed() -> void:
	GameManager.set_paused(false)
	_level_complete_panel.hide()
	_pause_button.visible = true
	_mobile_controls.mouse_filter = Control.MOUSE_FILTER_PASS
	GameManager.advance_to_next_level()


func _on_main_menu_pressed() -> void:
	GameManager.set_paused(false)
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func _on_game_completed() -> void:
	_final_score_label.text = "You Beat All 20 Levels! 🎉"
	_final_high_score_label.text = "Score: %d  |  Best: %d" % [GameManager.score, GameManager.high_score]
	_level_complete_panel.hide()
	_game_over_panel.show()
	_pause_button.visible = false
	AudioManager.play_level_up()
	AudioManager.stop_music()


func _on_pause_pressed() -> void:
	GameManager.toggle_pause()


func _on_resume_pressed() -> void:
	GameManager.set_paused(false)


func _on_paused_changed(is_paused: bool) -> void:
	_pause_panel.visible = is_paused
	_pause_button.visible = not is_paused and not _level_complete_panel.visible


func _on_game_over() -> void:
	_final_score_label.text = "Final Score: %d" % GameManager.score
	_final_high_score_label.text = "Best: %d" % GameManager.high_score
	_game_over_panel.show()
	_pause_panel.hide()
	_pause_button.visible = false
	_continue_btn.visible = not _continue_used
	_share_button.show()
	await get_tree().create_timer(0.3).timeout
	AudioManager.play_game_over()
	AudioManager.stop_music()


func _on_continue_pressed() -> void:
	if _continue_used:
		return
	if GameManager.spend_coins(20):
		_continue_used = true
		_continue_btn.hide()
		_game_over_panel.hide()
		GameManager.lives = 1
		GameManager.lives_changed.emit(GameManager.lives)
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("revive"):
			player.revive()
		GameManager.resume_after_continue()
		_pause_button.visible = true
		_mobile_controls.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		_continue_btn.text = "Not enough coins!"
		await get_tree().create_timer(1.5).timeout
		_continue_btn.text = "Continue  🪙 20"


func _on_share_pressed() -> void:
	var score_text := "I scored %d in Mobile Shooter! Can you beat me? 🚀" % GameManager.score
	if OS.has_feature("mobile"):
		OS.shell_open("https://play.google.com/")
	else:
		DisplayServer.clipboard_set(score_text)


func _on_rate_prompt() -> void:
	print("Rate prompt triggered — wire up platform plugin here")


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
