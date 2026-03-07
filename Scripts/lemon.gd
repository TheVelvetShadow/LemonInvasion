extends Fruit

class_name Lemon

func _die() -> void:
	rotation_speed = 0
	velocity = Vector2.ZERO
	$Sprite2D.texture = load("res://Assets/explosion.png")
	$Sprite2D.scale = Vector2(2.0, 2.0)
	await get_tree().create_timer(0.3).timeout
	queue_free()
