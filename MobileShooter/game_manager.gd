extends Node

var score: int = 0

signal score_changed(new_score: int)


func add_score(amount: int = 1) -> void:
	score += amount
	score_changed.emit(score)


func reset_score() -> void:
	score = 0
	score_changed.emit(score)
