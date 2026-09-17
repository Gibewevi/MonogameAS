extends Node2D

@export var cell_size: int = 3
@export var cloud_margin: float = 6.0
@export var grid_margin_px: float = 120.0

@export var active: bool = true
@export var use_perlin: bool = true

# --- paramètres nuages (seront randomisés) ---
@export var cloud_speed: Vector2 = Vector2(0.07, 0.03)
@export var cloud_scale: float = 0.02
@export var cloud_threshold: float = 0.55
@export var cloud_octaves: int = 1
@export var cloud_lacunarity: float = 2.0
@export var cloud_persistence: float = 0.5
# ---------------------------------------------

@export var terrain_path: NodePath = ^"../terrain_generator"
var terrain: Node = null

var cloud_offset: Vector2 = Vector2(0.0, 0.0)
var grid: Array = []
var _grid_w: int = 0
var _grid_h: int = 0

var noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	terrain = get_node_or_null(terrain_path)
	_configure_noise()
	_init_cloud_grid()

func _configure_noise() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 1.0

func _planet_radius() -> float:
	if terrain:
		return float(terrain.planet_radius_px)
	return 240.0

func _ensure_grid_sized_for_radius() -> void:
	var planet_radius: float = _planet_radius()
	if cell_size <= 0:
		cell_size = 12

	var half_span: float = planet_radius + grid_margin_px
	var diameter_px: float = half_span * 2.0

	var want_w: int = int(ceil(diameter_px / float(cell_size)))
	var want_h: int = int(ceil(diameter_px / float(cell_size)))

	if want_w != _grid_w or want_h != _grid_h:
		_grid_w = want_w
		_grid_h = want_h
		_init_cloud_grid()

func _init_cloud_grid() -> void:
	grid.resize(_grid_h)
	for y in _grid_h:
		grid[y] = []
		grid[y].resize(_grid_w)
		for x in _grid_w:
			grid[y][x] = 0

# FBM fractal
func _fbm(x: float, y: float, octaves: int, lacunarity: float, persistence: float) -> float:
	var total: float = 0.0
	var freq: float = 1.0
	var amp: float = 1.0
	var maxv: float = 0.0
	for i in range(octaves):
		total += (noise.get_noise_2d(x * freq, y * freq) * 0.5 + 0.5) * amp
		maxv += amp
		freq *= lacunarity
		amp *= persistence
	return total / maxv

func generate_clouds() -> void:
	_ensure_grid_sized_for_radius()

	var vp: Vector2 = get_viewport_rect().size
	var total_w: int = _grid_w * cell_size
	var total_h: int = _grid_h * cell_size
	var offset_x: float = (vp.x - total_w) / 2.0
	var offset_y: float = (vp.y - total_h) / 2.0
	var cx: float = offset_x + total_w / 2.0
	var cy: float = offset_y + total_h / 2.0
	var planet_radius: float = _planet_radius()

	for y in _grid_h:
		for x in _grid_w:
			var nx: float = (x * cloud_scale) + cloud_offset.x
			var ny: float = (y * cloud_scale) + cloud_offset.y
			var e: float = _fbm(nx, ny, cloud_octaves, cloud_lacunarity, cloud_persistence)

			if e > cloud_threshold:
				if e > cloud_threshold + 0.2:
					grid[y][x] = 51   # gris
				else:
					grid[y][x] = 50   # blanc
			else:
				grid[y][x] = 0

	for y in _grid_h:
		for x in _grid_w:
			var px: float = offset_x + x * cell_size + cell_size * 0.5
			var py: float = offset_y + y * cell_size + cell_size * 0.5
			var d: float = Vector2(px, py).distance_to(Vector2(cx, cy))
			if d > planet_radius + cloud_margin:
				grid[y][x] = 0

func update_clouds(delta: float) -> void:
	if active and use_perlin:
		cloud_offset.x += cloud_speed.x * delta
		cloud_offset.y += cloud_speed.y * delta
		generate_clouds()

func draw_clouds(canvas: Node2D) -> void:
	if _grid_w == 0 or _grid_h == 0:
		return

	var vp: Vector2 = get_viewport_rect().size
	var total_w: int = _grid_w * cell_size
	var total_h: int = _grid_h * cell_size
	var offset_x: float = (vp.x - total_w) / 2.0
	var offset_y: float = (vp.y - total_h) / 2.0

	for y in _grid_h:
		for x in _grid_w:
			var val: int = grid[y][x]
			if val == 50:
				canvas.draw_rect(
					Rect2(Vector2(offset_x + x * cell_size, offset_y + y * cell_size),
					Vector2(cell_size, cell_size)),
					Color(1,1,1,0.7),
					true
				)
			elif val == 51:
				canvas.draw_rect(
					Rect2(Vector2(offset_x + x * cell_size, offset_y + y * cell_size),
					Vector2(cell_size, cell_size)),
					Color(0.8,0.8,0.8,0.7),
					true
				)

func randomize_params() -> void:
	rng.randomize()

	cloud_scale = rng.randf_range(0.018, 0.024)
	cloud_threshold = rng.randf_range(0.32, 0.60)
	cloud_octaves = rng.randi_range(1, 3)             
	cloud_lacunarity = rng.randf_range(1.8, 2.3)      
	cloud_persistence = rng.randf_range(0.42, 0.65)   

	cloud_speed = Vector2(
		rng.randf_range(0.03, 0.12),
		rng.randf_range(0.02, 0.09)
	)

	cloud_margin = rng.randf_range(3.0, 8.0)
	grid_margin_px = max(grid_margin_px, cloud_margin + 64.0)

	noise.seed = rng.randi()
