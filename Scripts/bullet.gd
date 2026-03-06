extends Area2D

@export var bullet_speed = 700

func _ready() -> void:
	add_to_group("bullets")

func _physics_process(delta):
	position += transform.x * bullet_speed * delta

	if not get_viewport_rect().has_point(position):
		queue_free()
