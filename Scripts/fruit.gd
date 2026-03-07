extends Area2D

class_name Fruit

@export var rotation_speed = 3.0
@export var speed = 150.0
@export var max_hp = 3

var velocity = Vector2.ZERO
var hp: int

func _ready() -> void:
	hp = max_hp
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += velocity * delta
	rotation += rotation_speed * delta

	# Delete when off screen
	if not get_viewport_rect().grow(200).has_point(position):
		queue_free()

# Hit by a bullet
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		area.queue_free()
		hp -= 1
		if hp <= 0:
			_die()
		else:
			_flash()

func _die() -> void:
	_spawn_ring_effect()
	queue_free()

func _spawn_ring_effect() -> void:
	var ring = Line2D.new()
	ring.width = 6.0
	ring.default_color = Color.WHITE
	for i in 33:
		var angle = (float(i) / 32) * TAU
		ring.add_point(Vector2(cos(angle), sin(angle)) * 30.0)
	get_parent().add_child(ring)
	ring.global_position = global_position
	var tween = ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(4, 4), 0.4)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
	tween.tween_callback(ring.queue_free)

func _flash() -> void:
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.0)
	tween.tween_property(sprite, "modulate", Color(10, 10, 10, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
