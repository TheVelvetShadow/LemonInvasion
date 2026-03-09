extends Node2D

# Emitted after a fruit is instantiated and added to the scene.
# main.gd listens to this to wire up signals (camera shake, score).
signal fruit_spawned(fruit: Fruit)

# Add fruit scenes via the Inspector. Each fruit's spawn_weight
# property controls how likely it is to be chosen relative to the others.
@export var fruit_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 0.5

# Populated at startup by reading spawn_weight from each fruit scene.
# Cached so we don't re-instantiate every time a fruit spawns.
var _weights: Array[float] = []

func _ready() -> void:
	# Instantiate each scene temporarily just to read its spawn_weight,
	# then immediately free it. This runs once so the cost is negligible.
	for scene in fruit_scenes:
		var temp = scene.instantiate()
		_weights.append(temp.spawn_weight)
		temp.free()
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()

# Weighted random pick — higher spawn_weight = more likely to be chosen.
# Works by rolling a random number across the total weight, then walking
# through the cumulative sum until the roll is exceeded.
# Example: weights [3, 1] → 75% chance of index 0, 25% chance of index 1.
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
	# Fallback: return last entry (guards against floating point edge cases).
	return fruit_scenes.back()

func _on_spawn_timer_timeout() -> void:
	if fruit_scenes.is_empty():
		return
	# Pick a random point on the spawn path around the screen edge.
	var spawn_location = $SpawnPath/SpawnLocation
	spawn_location.progress_ratio = randf()

	var scene = _pick_scene()
	var fruit = scene.instantiate()
	
	# Fruit is added to main (the parent), not to the spawner,
	# so it moves freely in world space independently of this node.
	get_parent().add_child(fruit)
	fruit.global_position = spawn_location.global_position

	# Aim inward from the spawn point, with a random spread of ±45°.
	var direction = spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	fruit.velocity = Vector2.RIGHT.rotated(direction) * fruit.speed
	fruit_spawned.emit(fruit)
