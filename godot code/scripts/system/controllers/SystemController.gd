# res://scripts/views/SystemController.gd
extends Node2D
class_name SystemController
## Vue Système : affiche le soleil du système courant, calibré comme dans le proto.

# ⚠️ Garde le chemin de ton SunGenerator si différent
const SunGen := preload("res://scripts/galaxy/render/SunGenerator.gd")

@onready var _cam: Camera2D = $Camera2D if has_node("Camera2D") else null

var _sprite: Sprite2D
var _gs: Node = null  # Autoload GameState

# ---- Réglages issus du proto ----------------------------------------
# RATIO_PLANET_VIEW (Lua) -> ratio_system (export) : multiplie le "size" du sun_key
@export_range(1, 16, 1) var ratio_system: int = 6
# En système on veut 4 niveaux (10/11/20/21) → 4 “steps”
@export_range(2, 4, 1) var steps_system: int = 4
# ---------------------------------------------------------------------

func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
	if _gs == null:
		push_error("[SystemController] Autoload GameState introuvable.")
		return

	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # rendu pixel net
	add_child(_sprite)

	_refresh_sun()

	# Re-bake si la palette/seed change via HUD
	if _gs.has_signal("sun_key_changed"):
		_gs.connect("sun_key_changed", Callable(self, "_on_sun_key_changed"))

func _on_sun_key_changed(_k: Dictionary) -> void:
	_refresh_sun()

func _refresh_sun() -> void:
	if _gs == null or not _gs.has_method("get_sun_key"):
		return

	var k: Dictionary = _gs.call("get_sun_key")
	# NB: rename local pour éviter le warning ‘seed’ (shadow du global)
	var sun_seed: int = int(k.get("seed", 0))
	var class_id: int = int(k.get("class_id", 0))
	var celsus: int = int(k.get("celsus", 0))
	var base_size_px: int = int(k.get("size", 48))  # “diamètre” de base des textures
	var tex_px: int = clamp(base_size_px * ratio_system, 64, 1024)  # échelle système
	var steps: int = steps_system  # on force 4 tons en vue système

	# Comme dans le proto : celsus (>0) prime sur class_id
	var palette_param: int = (celsus if celsus > 0 else class_id)

	var baked: Dictionary = SunGen.bake(sun_seed, palette_param, tex_px, steps)
	var tex: Texture2D = baked.get("albedo", null)
	if tex == null:
		push_error("[SystemController] SunGenerator.bake() n’a pas renvoyé de texture.")
		return

	_sprite.texture = tex
	_sprite.scale = Vector2.ONE  # on garde l’échelle de texture, pas de scale arbitraire

	# Centre l’affichage dans le viewport
	var viewport_size: Vector2 = get_viewport_rect().size
	_sprite.position = viewport_size * 0.5
	if _cam:
		_cam.position = _sprite.position
