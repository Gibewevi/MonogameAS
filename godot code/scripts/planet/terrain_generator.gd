extends Node2D

@export var planet_radius_px: int = 70
@export var cell_size: int = 3

# --- Paramètres bruit/relief
var elev_scale       := 0.04
var elev_octaves     := 2
var elev_lacunarity  := 1
var elev_persistence := 0.45
var elev_sea_level   := 0.55 #0,35
var elev_beach_band  := 0.02
var elev_shelf_band  := 0.10
var elev_hill_level  := 0.65
var elev_mtn_level   := 0.80

# --- Données
var grid: Array = []
var elev_grid: Array = []
var _grid_w := 0
var _grid_h := 0

var noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var noise_offset_x := 0.0
var noise_offset_y := 0.0

# Palette courante (fallback si aucune usine n’est utilisée)
var current_palette: Dictionary = {
	"deep_water": Color(0.1, 0.2, 0.5),
	"shelf_water": Color(0.2, 0.4, 0.7),
	"beach": Color(0.9, 0.8, 0.5),
	"plains": Color(0.3, 0.6, 0.2),
	"hills": Color(0.2, 0.5, 0.1),
	"mountains": Color(0.5, 0.5, 0.5),
	"_has_beaches": true
}

func regenerate() -> void:
	noise_offset_x = rng.randf_range(0.0, 1000.0)
	noise_offset_y = rng.randf_range(0.0, 1000.0)
	generate_planet()

func _configure_noise() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 1.0

func _snap_planet_radius_to_cell() -> void:
	if cell_size <= 0:
		cell_size = 12
	if planet_radius_px % cell_size != 0:
		planet_radius_px += cell_size - (planet_radius_px % cell_size)

func _adjust_radius_to_viewport() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var max_radius: float = min(vp.x, vp.y) * 0.48
	if planet_radius_px > max_radius:
		planet_radius_px = int(max_radius)
		_snap_planet_radius_to_cell()

func _fbm(x: float, y: float, octaves: int, lacunarity: float, persistence: float) -> float:
	var total := 0.0
	var freq := 1.0
	var amp := 1.0
	var maxv := 0.0
	for i in range(octaves):
		total += (noise.get_noise_2d(x * freq, y * freq) * 0.5 + 0.5) * amp
		maxv += amp
		freq *= lacunarity
		amp *= persistence
	return total / maxv

func _smooth_elev() -> void:
	for iter in range(2):
		var new_elev: Array = []
		new_elev.resize(_grid_h)
		for y in range(_grid_h):
			new_elev[y] = []
			new_elev[y].resize(_grid_w)
			for x in range(_grid_w):
				new_elev[y][x] = null

		for y in range(_grid_h):
			for x in range(_grid_w):
				if elev_grid[y][x] == null:
					continue
				var sum := 0.0
				var count := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var ny := y + dy
						var nx := x + dx
						if ny >= 0 and ny < _grid_h and nx >= 0 and nx < _grid_w and elev_grid[ny][nx] != null:
							sum += elev_grid[ny][nx]
							count += 1
				if count > 0:
					new_elev[y][x] = elev_grid[y][x] * 0.6 + (sum / count) * 0.4
				else:
					new_elev[y][x] = elev_grid[y][x]
		elev_grid = new_elev

func generate_planet() -> void:
	_configure_noise()
	_snap_planet_radius_to_cell()
	_adjust_radius_to_viewport()

	var diameter := planet_radius_px * 2
	_grid_w = int(ceil(float(diameter) / float(cell_size)))
	_grid_h = int(ceil(float(diameter) / float(cell_size)))

	grid.resize(_grid_h)
	elev_grid.resize(_grid_h)
	for y in range(_grid_h):
		grid[y] = []
		grid[y].resize(_grid_w)
		elev_grid[y] = []
		elev_grid[y].resize(_grid_w)

	var vp := get_viewport_rect().size
	var total_w := _grid_w * cell_size
	var total_h := _grid_h * cell_size
	var offset_x := (vp.x - total_w) / 2.0
	var offset_y := (vp.y - total_h) / 2.0
	var cx := offset_x + total_w / 2.0
	var cy := offset_y + total_h / 2.0
	var radius := float(planet_radius_px)

	for gy in range(_grid_h):
		for gx in range(_grid_w):
			var cell_cx := offset_x + gx * cell_size + cell_size * 0.5
			var cell_cy := offset_y + gy * cell_size + cell_size * 0.5
			var inside := Vector2(cell_cx, cell_cy).distance_to(Vector2(cx, cy)) <= radius
			if not inside:
				grid[gy][gx] = null
				elev_grid[gy][gx] = null
				continue

			var nx := (gx + noise_offset_x) * elev_scale
			var ny := (gy + noise_offset_y) * elev_scale
			var e := _fbm(nx, ny, elev_octaves, elev_lacunarity, elev_persistence)
			elev_grid[gy][gx] = e

	_smooth_elev()

	# Classification basée sur élévations lissées
	for gy in range(_grid_h):
		for gx in range(_grid_w):
			if elev_grid[gy][gx] == null:
				continue
			var e: float = elev_grid[gy][gx]

			var code := 10
			if e < (elev_sea_level - elev_shelf_band):
				code = 21  # Eau profonde
			elif e < elev_sea_level:
				code = 20  # Plateau continental
			elif e < (elev_sea_level + elev_beach_band):
				if current_palette.has("_has_beaches") and current_palette["_has_beaches"]:
					code = 11  # Plage si la palette le permet
				else:
					code = 10  # Pas de plages → plaine
			elif e < elev_hill_level:
				code = 10  # Plaines
			elif e < elev_mtn_level:
				code = 12  # Collines
			else:
				code = 13  # Montagnes
			grid[gy][gx] = code

func draw(canvas: Node2D) -> void:
	if _grid_w == 0 or _grid_h == 0:
		return

	var vp := get_viewport_rect().size
	var total_w := _grid_w * cell_size
	var total_h := _grid_h * cell_size
	var offset_x := (vp.x - total_w) / 2.0
	var offset_y := (vp.y - total_h) / 2.0

	for y in range(_grid_h):
		for x in range(_grid_w):
			var code = grid[y][x]
			if code == null:
				continue
			var rect := Rect2(
				Vector2(offset_x + x * cell_size, offset_y + y * cell_size),
				Vector2(cell_size, cell_size)
			)
			var col: Color
			match code:
				21: col = current_palette["deep_water"]
				20: col = current_palette["shelf_water"]
				11: col = current_palette["beach"]
				10: col = current_palette["plains"]
				12: col = current_palette["hills"]
				13: col = current_palette["mountains"]
				_:  continue
			canvas.draw_rect(rect, col, true)
