extends Fruit

class_name Lemon

func _die() -> void:
	_spawn_god_rays()
	super._die()

func _spawn_god_rays() -> void:
	for i in 10:
		var ray = Line2D.new()
		ray.width = 4.0
		ray.default_color = Color(1, 1, 0.8, 1)
		var angle = (float(i) / 10) * TAU + randf_range(-0.15, 0.15)
		var dir = Vector2.RIGHT.rotated(angle)
		ray.add_point(dir * 20.0)
		ray.add_point(dir * 20.0)
		get_parent().add_child(ray)
		ray.global_position = global_position
		var tween = ray.create_tween()
		tween.tween_method(func(p: Vector2): ray.set_point_position(1, p), dir * 20.0, dir * 150.0, 0.35)
		tween.parallel().tween_property(ray, "modulate:a", 0.0, 0.35)
		tween.tween_callback(ray.queue_free)
