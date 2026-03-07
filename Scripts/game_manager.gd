extends Node

var score := 0

signal score_changed(new_score: int)

func register_fruit(fruit: Fruit) -> void:
	fruit.hit.connect(_on_fruit_hit)
	fruit.destroyed.connect(_on_fruit_destroyed)

func _on_fruit_hit(points: int) -> void:
	score += points
	score_changed.emit(score)

func _on_fruit_destroyed(points: int) -> void:
	score += points
	score_changed.emit(score)
