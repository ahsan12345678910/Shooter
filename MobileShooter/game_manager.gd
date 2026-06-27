extends Node

const MAX_LIVES: int = 3
const HIGH_SCORE_PATH: String = "user://highscore.cfg"
const COINS_PATH: String = "user://coins.cfg"
const RATE_PROMPT_SCORE: int = 50
const RATE_PROMPT_KEY: String = "rate_prompted"

var score: int = 0
var lives: int = MAX_LIVES
var high_score: int = 0
var is_game_over: bool = false
var is_paused: bool = false
var enemy_speed_multiplier: float = 1.0

var current_level: int = 1
var enemies_killed_this_level: int = 0
var enemies_required_this_level: int = 0
var level_active: bool = false

var coins: int = 0
var total_coins_earned: int = 0
var coin_multiplier: int = 1

var _rate_prompted: bool = false

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal high_score_changed(new_high_score: int)
signal game_over
signal paused_changed(is_paused: bool)
signal level_started(level_number: int)
signal level_completed(level_number: int, coins_reward: int)
signal level_progress_changed(killed: int, required: int)
signal game_completed
signal game_continued
signal coins_changed(new_coins: int)
signal rate_prompt_requested


func _ready() -> void:
	_load_high_score()
	_load_coins()
	var cfg := ConfigFile.new()
	if cfg.load(HIGH_SCORE_PATH) == OK:
		_rate_prompted = bool(cfg.get_value("game", RATE_PROMPT_KEY, false))


func reset_game() -> void:
	score = 0
	lives = MAX_LIVES + (1 if UpgradeManager.extra_life else 0)
	is_game_over = false
	is_paused = false
	enemy_speed_multiplier = 1.0
	current_level = 1
	enemies_killed_this_level = 0
	enemies_required_this_level = 0
	level_active = false
	coin_multiplier = 1
	get_tree().paused = false
	score_changed.emit(score)
	lives_changed.emit(lives)


func start_level(level_number: int) -> void:
	current_level = level_number
	enemies_killed_this_level = 0
	var data := LevelData.get_level(level_number)
	enemies_required_this_level = data["enemy_count"]
	enemy_speed_multiplier = data["enemy_speed"]
	level_active = true
	level_started.emit(level_number)
	level_progress_changed.emit(enemies_killed_this_level, enemies_required_this_level)


func on_enemy_killed() -> void:
	_register_enemy_cleared()


func on_enemy_escaped() -> void:
	if not level_active or is_game_over:
		return
	enemies_required_this_level = maxi(0, enemies_required_this_level - 1)
	level_progress_changed.emit(enemies_killed_this_level, enemies_required_this_level)
	if enemies_killed_this_level >= enemies_required_this_level and enemies_required_this_level > 0:
		_complete_level()
	elif enemies_required_this_level <= 0:
		_complete_level()


func _register_enemy_cleared() -> void:
	if not level_active:
		return
	enemies_killed_this_level += 1
	level_progress_changed.emit(enemies_killed_this_level, enemies_required_this_level)
	if is_game_over:
		return
	if enemies_killed_this_level >= enemies_required_this_level:
		_complete_level()


func check_and_complete_level() -> void:
	if is_game_over:
		return
	if enemies_killed_this_level >= enemies_required_this_level:
		if not level_active:
			level_active = true
		_complete_level()


func resume_after_continue() -> void:
	is_game_over = false
	is_paused = false
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	if not AudioManager.is_music_playing():
		AudioManager.play_music()
	if enemies_killed_this_level < enemies_required_this_level:
		level_active = true
	else:
		level_active = false
		await get_tree().create_timer(1.2).timeout
		if not is_game_over:
			advance_to_next_level()
			return
	game_continued.emit()


func _complete_level() -> void:
	level_active = false
	var data := LevelData.get_level(current_level)
	var reward: int = data["coins_reward"]
	add_coins(reward)
	AudioManager.play_level_up()
	level_completed.emit(current_level, reward)


func advance_to_next_level() -> void:
	if current_level >= LevelData.MAX_LEVEL:
		game_completed.emit()
		return
	start_level(current_level + 1)


func get_score_per_kill() -> int:
	return LevelData.get_level(current_level).get("score_per_kill", 1)


func add_score(amount: int = 1) -> void:
	if is_game_over:
		return
	score += amount
	score_changed.emit(score)
	_try_update_high_score()
	if score % 10 == 0:
		add_coins(1 * coin_multiplier)
	if not _rate_prompted and score >= RATE_PROMPT_SCORE:
		_rate_prompted = true
		var cfg := ConfigFile.new()
		cfg.load(HIGH_SCORE_PATH)
		cfg.set_value("game", RATE_PROMPT_KEY, true)
		cfg.save(HIGH_SCORE_PATH)
		rate_prompt_requested.emit()


func add_life(amount: int = 1) -> void:
	if is_game_over:
		return
	lives += amount
	lives_changed.emit(lives)


func lose_life() -> void:
	if is_game_over:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("absorb_hit") and player.absorb_hit():
		return
	if player and player.has_method("flash_damage"):
		player.flash_damage()
	AudioManager.play_player_hit()
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		is_game_over = true
		_try_update_high_score()
		game_over.emit()


func toggle_pause() -> void:
	if is_game_over:
		return
	set_paused(not is_paused)


func set_paused(paused: bool) -> void:
	if is_game_over and paused:
		return
	is_paused = paused
	get_tree().paused = paused
	AudioManager.set_music_paused(paused)
	paused_changed.emit(paused)


func add_coins(amount: int) -> void:
	coins += amount
	total_coins_earned += amount
	coins_changed.emit(coins)
	_save_coins()


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	_save_coins()
	return true


func award_boss_kill_coins(level_number: int) -> void:
	var bonus := 10 + level_number * 2
	add_coins(bonus)


func _load_coins() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(COINS_PATH) != OK:
		return
	coins = int(cfg.get_value("economy", "coins", 0))
	total_coins_earned = int(cfg.get_value("economy", "total_earned", 0))


func _save_coins() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("economy", "coins", coins)
	cfg.set_value("economy", "total_earned", total_coins_earned)
	cfg.save(COINS_PATH)


func _try_update_high_score() -> void:
	if score <= high_score:
		return
	high_score = score
	_save_high_score()
	high_score_changed.emit(high_score)


func _load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load(HIGH_SCORE_PATH) != OK:
		high_score = 0
		return
	high_score = int(config.get_value("game", "high_score", 0))
	high_score_changed.emit(high_score)


func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "high_score", high_score)
	config.save(HIGH_SCORE_PATH)
