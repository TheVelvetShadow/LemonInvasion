extends Fruit

class_name Banana

const TIER_SCALE = [0.4, 0.28, 0.18, 0.11]
const TIER_SPEED = [150.0, 190.0, 230.0, 270.0]
const TIER_HP    = [3, 2, 1, 1]
const TIER_POINTS = [10, 20, 50, 75]
var fruit_colour = Color(0.988, 0.918, 0.875, 1.0)

func _ready() -> void:
	max_tier = TIER_SCALE.size() - 1
	scale = Vector2.ONE * TIER_SCALE[tier]
	speed = TIER_SPEED[tier]
	max_hp = TIER_HP[tier]
	points = TIER_POINTS[tier]
	super()


func _play_death_animation() -> void:
	if tier == 0:
		$Sprite2D.texture = load("res://Assets/explosion.png")
		$Sprite2D.self_modulate = fruit_colour
		$Sprite2D.scale = Vector2(2.5, 2.5)
		var tween = create_tween()
		tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.2)
		await tween.finished
