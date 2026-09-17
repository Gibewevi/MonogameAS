# scripts/galaxy/GalaxySun.gd
extends Node2D

var radius: float = 4.0
var color: Color = Color(1, 1, 1) # blanc par défaut

func setup(pos_in_tile: Vector2, r: float = 4.0, c: Color = Color(1, 1, 1)) -> void:
	position = pos_in_tile   # Position locale dans la tuile
	radius = r
	color = c
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
