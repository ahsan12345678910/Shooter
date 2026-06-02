extends Node

const MAX_LIVES: int = 3

var score: int = 0
var lives: int = MAX_LIVES
var is_game_over: bool = false

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over


func reset_game() -> void:
	score = 0
	lives = MAX_LIVES
	is_game_over = false
	score_changed.emit(score)
	lives_changed.emit(lives)


func add_score(amount: int = 1) -> void:
	if is_game_over:
		return
	score += amount
	score_changed.emit(score)


func add_life(amount: int = 1) -> void:
	if is_game_over:
		return
	lives += amount
	lives_changed.emit(lives)


func lose_life() -> void:
	if is_game_over:
		return
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		is_game_over = true
		game_over.emit()
