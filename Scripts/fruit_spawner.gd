extends Node2D

signal fruit_spawned(fruit: Fruit)

@export var fruit_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 0.75

var _weights: Array[float] = []

func _ready() -> void:
	for scene in fruit_scenes:
		var temp = scene.instantiate()
		_weights.append(temp.spawn_weight)
		temp.free()
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()

func _pick_scene() -> PackedScene:
	var total = 0.0
	for w in _weights:
		total += w
	var roll = randf() * total
	var cumulative = 0.0
	for i in fruit_scenes.size():
		cumulative += _weights[i]
		if roll < cumulative:
			return fruit_scenes[i]
	return fruit_scenes.back()

func _on_spawn_timer_timeout() -> void:
	if fruit_scenes.is_empty():
		return
	var spawn_location = $SpawnPath/SpawnLocation
	spawn_location.progress_ratio = randf()

	var scene = _pick_scene()
	var fruit = scene.instantiate()
	get_parent().add_child(fruit)
	fruit.global_position = spawn_location.global_position

	var direction = spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	fruit.velocity = Vector2.RIGHT.rotated(direction) * fruit.speed
	fruit_spawned.emit(fruit)
