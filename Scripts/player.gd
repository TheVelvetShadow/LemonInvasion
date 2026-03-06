extends Sprite2D

@export var speed = 400
@export var rotation_speed = 5.0

@onready var bullet_prefab = preload("res://Scenes/bullet.tscn")
 

func _process(delta):
	# Left stick moves the ship
	var move = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	if move.length() > 0.1:
		position += move * speed * delta

	# Right stick rotates the ship
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(joy_x) > 0.1:
		rotation += joy_x * rotation_speed * delta

	# Fires
	if Input.is_action_just_pressed("player_shoot"):
		var bullet = bullet_prefab.instantiate()
		bullet.position = position
		get_parent().add_child(bullet)

	# Keep ship on screen
	var bounds = get_viewport_rect()
	position = position.clamp(bounds.position, bounds.end)
