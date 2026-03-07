extends Fruit

class_name Lemon
	

func _die() -> void:
	rotation_speed = 0
	velocity = Vector2.ZERO
	$Sprite2D.texture = load("res://Assets/explosion.png")
	$Sprite2D.scale = Vector2(2.5, 2.5)
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.2)
	await tween.finished
	destroyed.emit(points)
	queue_free()
