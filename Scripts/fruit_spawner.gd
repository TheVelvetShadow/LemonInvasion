extends Node2D

signal fruit_spawned(fruit: Fruit)

@export var fruit_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 0.75

func _ready() -> void:
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	if fruit_scenes.is_empty():
		return
	var spawn_location = $SpawnPath/SpawnLocation
	spawn_location.progress_ratio = randf()

	var scene = fruit_scenes.pick_random()
	var fruit = scene.instantiate()
	get_parent().add_child(fruit)
	fruit.global_position = spawn_location.global_position

	var direction = spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	fruit.velocity = Vector2.RIGHT.rotated(direction) * fruit.speed
	fruit_spawned.emit(fruit)
