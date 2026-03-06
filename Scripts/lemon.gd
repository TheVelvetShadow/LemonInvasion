extends Area2D

class_name Lemon

@export var lemon_rotation_speed = 3.0
@export var lemon_speed = 150.0

var velocity = Vector2.ZERO

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += velocity * delta
	rotation += lemon_rotation_speed * delta

	# Delete when off screen
	if not get_viewport_rect().grow(200).has_point(position):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Hit by a bullet
	if area.is_in_group("bullets"):
		area.queue_free()
		queue_free()
