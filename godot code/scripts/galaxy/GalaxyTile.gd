extends Node2D
## Tuile qui dessine les soleils via l'autoload GlobalSunCache (SunGenerator derrière).

const SUN_RADIUS := 4.0

var tile_x:int
var tile_y:int
var tile_size:int = 32
var base_color:Color = Color(1, 0, 0, 1)

var _fill_alpha: float = 0.25
var _suns_local: Array[Vector2] = []
var _hover_id: int = -1

var _cache: Node = null

func _init(p_tx:int = 0, p_ty:int = 0, p_size:int = 32, p_color:Color = Color.RED) -> void:
	tile_x = p_tx
	tile_y = p_ty
	tile_size = p_size
	base_color = p_color
	position = Vector2(tile_x * tile_size, tile_y * tile_size)

func _ready() -> void:
	if has_node("/root/GlobalSunCache"):
		_cache = get_node("/root/GlobalSunCache")
	elif has_node("/root/GlobalSunCash"):
		_cache = get_node("/root/GlobalSunCash")

func set_fill_alpha(a:float) -> void:
	_fill_alpha = clamp(a, 0.0, 1.0)
	queue_redraw()

func set_suns_local(points:Array[Vector2]) -> void:
	_suns_local = points.duplicate()
	queue_redraw()

func clear_hover() -> void:
	_hover_id = -1
	queue_redraw()

func set_hovered_sun(id:int) -> void:
	_hover_id = id
	queue_redraw()

func get_sun_world_pos(id:int) -> Vector2:
	if id < 0 or id >= _suns_local.size(): return Vector2.ZERO
	return position + _suns_local[id]

func get_sun_at_world_pos(world_pos:Vector2) -> int:
	var local := world_pos - position
	for i in _suns_local.size():
		if local.distance_to(_suns_local[i]) <= SUN_RADIUS + 1.0:
			return i
	return -1

func _choose_lod() -> int:
	var cam := get_viewport().get_camera_2d()
	var z: float = cam.zoom.x if cam else 1.0
	return 1 if z >= 2.0 else 0

static func _seed_from_point(p:Vector2) -> int:
	var h:int = int(p.x) ^ (int(p.y) << 1)
	h = h ^ (h << 13)
	h = h ^ (h >> 17)
	h = h ^ (h << 5)
	return h

static func _class_from_seed(h:int) -> int:
	return abs(h) % 7

func _draw() -> void:
	if _fill_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(tile_size, tile_size)),
			Color(base_color.r, base_color.g, base_color.b, _fill_alpha), true)

	if _suns_local.is_empty():
		return

	var lod := _choose_lod()
	var grid_px := 8 if lod == 0 else 16
	var steps := 3

	for i in _suns_local.size():
		var p: Vector2 = _suns_local[i]
		var seed_val := _seed_from_point(position + p)
		var class_id := _class_from_seed(seed_val)

		if _cache != null:
			var atlas:Dictionary = _cache.get_or_bake(lod, seed_val, class_id, grid_px, steps)
			var tex_halo:Texture2D = atlas.get("halo", null)
			var tex_sun: Texture2D = atlas.get("albedo", null)

			var o := Vector2(grid_px, grid_px) * -0.5
			if tex_halo:
				draw_texture(tex_halo, p + o)
			if tex_sun:
				draw_texture(tex_sun, p + o)
		else:
			draw_circle(p, float(grid_px) * 0.5, Color.WHITE)

		if i == _hover_id:
			var r := float(grid_px) * 0.5 + 1.5
			draw_arc(p, r, 0.0, TAU, 24, Color(1,1,1,0.35), 1.2)
