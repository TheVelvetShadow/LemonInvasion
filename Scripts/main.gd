extends Node2D

@export var lemon_mob: PackedScene
@onready var ship = $player
@export var spawn_weight = 0.75


func _ready() -> void:
	$SpawnTimer.wait_time = spawn_weight
	$SpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	var spawn_location = $SpawnPath/SpawnLocation
	spawn_location.progress_ratio = randf()

	var lemon = lemon_mob.instantiate()
	add_child(lemon)
	lemon.position = spawn_location.position

	var direction = spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	lemon.velocity = Vector2.RIGHT.rotated(direction) * lemon.speed
	GameManager.register_fruit(lemon)
