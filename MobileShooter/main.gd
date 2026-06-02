extends Node2D

@onready var _score_label: Label = $UI/ScoreLabel


func _ready() -> void:
	GameManager.reset_score()
	GameManager.score_changed.connect(_on_score_changed)
	_on_score_changed(GameManager.score)


func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score
