extends Area2D

class_name Fruit

signal hit(points: int)
signal destroyed(points: int)
signal dying

@export var rotation_speed = 3.0
@export var speed = 150.0
@export var max_hp = 3
@export var points: int = 10
@export var hit_points: int = 1

var tier: int = 0
var max_tier: int = 0
var velocity = Vector2.ZERO
var hp: int
var split_amount = 3
var is_dying: bool = false

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
	if area.is_in_group("bullets") and not area.is_queued_for_deletion() and not is_dying:
		area.queue_free()
		hp -= 1
		if hp <= 0:
			_split()
			_die()
		else:
			hit.emit(hit_points)
			_flash()


func _split() -> void:
	if tier >= max_tier:
		return
	for i in split_amount :
		var child = load(scene_file_path).instantiate()
		child.tier = tier + 1
		get_parent().add_child(child)
		child.global_position = global_position
		var spread = PI / 4
		var angle = lerp(-spread, spread, float(i))
		child.velocity = velocity.rotated(angle) * 1.2


func _play_death_animation() -> void:
	pass


func _die() -> void:
	is_dying = true
	dying.emit()
	rotation_speed = 0
	velocity = Vector2.ZERO
	await _play_death_animation()
	destroyed.emit(points)
	queue_free()


func _flash() -> void:
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.0)
	tween.tween_property(sprite, "modulate", Color(10, 10, 10, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
