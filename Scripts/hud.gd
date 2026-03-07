extends CanvasLayer

@onready var score_label = $ScoreLabel

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	score_label.text = "Score: 0"

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score
