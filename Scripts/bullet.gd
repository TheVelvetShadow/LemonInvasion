
# 1. Travel in a direction (a Vector2 that gets set at spawn time)
#  2. Move at a proper speed (try 600)
#  3. Delete itself when it goes off-screen
extends Area2D

@export var bullet_speed = 700

func _physics_process(delta):
	position += transform.x * bullet_speed * delta
	
	if not get_viewport_rect().has_point(position):
		queue_free()
		
