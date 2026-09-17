extends Node2D

func _ready() -> void:
	print("🌍 PlanetView chargée")

	var planet_scene: PackedScene = load("res://scenes/entities/planet.tscn")
	if not planet_scene:
		push_error("⚠️ Impossible de charger planet.tscn")
		return

	var planet_instance: Node2D = planet_scene.instantiate()

	# Centrer sur l’écran
	var viewport_size: Vector2 = get_viewport_rect().size
	planet_instance.position = Vector2.ZERO

	add_child(planet_instance)
