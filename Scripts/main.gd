extends Node2D

@export var lemon_mob: PackedScene
@onready var ship = $player

func _ready() -> void:
	$LemonSpawnTimer.wait_time = 1.5
	$LemonSpawnTimer.start()

func _process(delta: float) -> void:
	pass

func _on_lemon_spawn_timer_timeout() -> void:
	var lemon_spawn_location = $SpawnPath/SpawnLocation
	lemon_spawn_location.progress_ratio = randf()

	var lemon = lemon_mob.instantiate()
	add_child(lemon)
	lemon.position = lemon_spawn_location.position

	var direction = lemon_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	lemon.velocity = Vector2.RIGHT.rotated(direction) * lemon.lemon_speed
