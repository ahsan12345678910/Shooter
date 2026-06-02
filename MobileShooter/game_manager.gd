extends Node

const MAX_LIVES: int = 3
const HIGH_SCORE_PATH: String = "user://highscore.cfg"
const SPEED_INTERVAL_SEC: float = 30.0
const SPEED_INCREASE_PER_TIER: float = 0.12
const BOSS_SCORE_INTERVAL: int = 100

var score: int = 0
var lives: int = MAX_LIVES
var high_score: int = 0
var is_game_over: bool = false
var is_paused: bool = false
var elapsed_time: float = 0.0
var enemy_speed_multiplier: float = 1.0

var _next_boss_score: int = BOSS_SCORE_INTERVAL
var _speed_tier: int = 0

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal high_score_changed(new_high_score: int)
signal game_over
signal paused_changed(is_paused: bool)
signal boss_spawn_requested(milestone: int)
signal difficulty_changed(speed_multiplier: float)


func _ready() -> void:
	_load_high_score()


func _process(delta: float) -> void:
	if is_game_over or is_paused:
		return

	elapsed_time += delta
	var new_tier := int(elapsed_time / SPEED_INTERVAL_SEC)
	if new_tier != _speed_tier:
		_speed_tier = new_tier
		enemy_speed_multiplier = 1.0 + float(_speed_tier) * SPEED_INCREASE_PER_TIER
		difficulty_changed.emit(enemy_speed_multiplier)


func reset_game() -> void:
	score = 0
	lives = MAX_LIVES
	is_game_over = false
	is_paused = false
	elapsed_time = 0.0
	enemy_speed_multiplier = 1.0
	_speed_tier = 0
	_next_boss_score = BOSS_SCORE_INTERVAL
	get_tree().paused = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	difficulty_changed.emit(enemy_speed_multiplier)


func add_score(amount: int = 1) -> void:
	if is_game_over:
		return
	var old_score := score
	score += amount
	score_changed.emit(score)
	_try_update_high_score()
	_check_boss_milestones(old_score, score)


func add_life(amount: int = 1) -> void:
	if is_game_over:
		return
	lives += amount
	lives_changed.emit(lives)


func lose_life() -> void:
	if is_game_over:
		return
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
	if is_game_over:
		return
	is_paused = paused
	get_tree().paused = paused
	AudioManager.set_music_paused(paused)
	paused_changed.emit(paused)


func get_spawn_count_for_score() -> int:
	return clampi(1 + score / 20, 1, 4)


func get_spawn_interval_for_score(base_interval: float) -> float:
	var reduction := float(score) * 0.015
	return maxf(0.45, base_interval - reduction)


func get_boss_hp_for_milestone(milestone: int) -> int:
	var tier: int = maxi(1, milestone / BOSS_SCORE_INTERVAL)
	return 6 + tier * 4


func _check_boss_milestones(_old_score: int, new_score: int) -> void:
	while new_score >= _next_boss_score:
		boss_spawn_requested.emit(_next_boss_score)
		_next_boss_score += BOSS_SCORE_INTERVAL


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
