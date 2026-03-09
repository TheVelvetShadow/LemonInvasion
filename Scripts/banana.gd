extends Fruit

class_name Banana

func _ready() -> void:
	fruit_colour = Color(0.988, 0.918, 0.875, 1.0)
	tier_scale  = [0.4, 0.28, 0.18, 0.11]
	tier_speed  = [150.0, 190.0, 230.0, 270.0]
	tier_hp     = [3, 2, 1, 1]
	tier_points = [10, 20, 50, 75]
	super()
