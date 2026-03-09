extends Fruit

class_name Strawberry

func _ready() -> void:
	fruit_colour = Color("e88482ff")
	tier_scale  = [0.4, 0.28, 0.18, 0.11]
	tier_speed  = [190.0, 210.0, 230.0, 270.0]
	tier_hp     = [3, 3, 3, 3]
	tier_points = [10, 20, 50, 75]
	super()
