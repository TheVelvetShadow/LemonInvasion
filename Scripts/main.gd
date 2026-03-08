extends Node2D

func _ready() -> void:
	$FruitSpawner.fruit_spawned.connect(_on_fruit_spawned)

func _on_fruit_spawned(fruit: Fruit) -> void:
	fruit.dying.connect($Camera_shake.apply_shake)
	GameManager.register_fruit(fruit)
