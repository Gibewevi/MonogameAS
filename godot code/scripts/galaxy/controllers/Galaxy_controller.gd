extends Node2D
# GalaxyView.gd — version typée + persistance via GameState

# ------------------------------------------------------------------
# Dépendances
# ------------------------------------------------------------------
const GalaxyTile := preload("res://scripts/galaxy/GalaxyTile.gd")

@onready var camera: Camera2D = $Camera2D
@onready var debug_label: Label = $CanvasLayer/Label

# ------------------------------------------------------------------
# Paramètres grille
# ------------------------------------------------------------------
const TILE_SIZE: int = 32
const START_RADIUS: int = 1
const START_COLOR: Color = Color(1, 0, 0)      # rouge
const DISCOVER_COLOR: Color = Color(0, 1, 0)   # vert

# ------------------------------------------------------------------
# Caméra
# ------------------------------------------------------------------
var zoom_levels: Array[float] = [1.0, 2.0, 3.0, 4.0]
var current_zoom_index: int = 0
var camera_speed: float = 400.0

# ------------------------------------------------------------------
# Génération
# ------------------------------------------------------------------
var generated_tiles: Dictionary = {}  # Vector2i -> GalaxyTile (Node2D)

# ------------------------------------------------------------------
# Bruit / Densité
# ------------------------------------------------------------------
var noise: FastNoiseLite = FastNoiseLite.new()
const NOISE_FREQ: float = 0.08
const FILL_MIN: float = 0.05
const FILL_MAX: float = 0.65

# ------------------------------------------------------------------
# Sampling continu / raréfaction
# ------------------------------------------------------------------
const CANDIDATE_STEP: int = 8
const CANDIDATE_JITTER: float = 3.0

# Dépend du rayon “disque” défini dans GalaxyTile
var SUN_RADIUS: float = 4.0          # sera écrasé en _ready()
var BORDER_MARGIN: float = 4.5       # sera écrasé en _ready()
var MIN_DIST: float = 8.6            # sera écrasé en _ready()

const DENSITY_SCALE: float = 0.45
const MAX_SUNS_PER_TILE: int = 4

# Spatial hash : cell size = MIN_DIST
var _spatial: Dictionary = {}        # Vector2i -> Array[Vector2]
var _world_seed: int = 0

# ------------------------------------------------------------------
# Debug / survol
# ------------------------------------------------------------------
var last_click_info: String = ""
var _hover_tile: Node2D = null
var _hover_id: int = -1

# ------------------------------------------------------------------
# Accès GameState (autoload)
# ------------------------------------------------------------------
func _resolve_gamestate() -> Node:
	# Autoload “GameState” prioritaire
	var n: Node = get_node_or_null("/root/GameState")
	if n != null:
		return n
	# Fallback éventuel si tu utilises un autre nom (ex: GameStateAuto)
	n = get_node_or_null("/root/GameStateAuto")
	if n != null:
		return n
	# Pas trouvable ? on travaille en “stateless” sans crash.
	return null

var _gs: Node = null

# ------------------------------------------------------------------
# Seed persistante (ne JAMAIS randomize ici)
# ------------------------------------------------------------------
func _get_persistent_seed() -> int:
	# 1) Autoload prioritaire : GameModeAuto (si présent)
	var gm: Node = get_node_or_null("/root/GameModeAuto")
	if gm != null and gm.has_method("get"):
		var s: int = int(gm.get("current_seed"))
		if s != 0:
			return s
	# 2) Fallback possible : /root/GameMode (si tu l’utilises)
	gm = get_node_or_null("/root/GameMode")
	if gm != null and gm.has_method("get"):
		var s2: int = int(gm.get("current_seed"))
		if s2 != 0:
			return s2
	# 3) Dernier recours : garder l’ancienne valeur, sinon fixe
	if _world_seed != 0:
		return _world_seed
	return 123456789

# ------------------------------------------------------------------
# Cycle de vie
# ------------------------------------------------------------------
func _ready() -> void:
	_gs = _resolve_gamestate()
	_world_seed = _get_persistent_seed()

	# Rayon/ marges suivant GalaxyTile
	SUN_RADIUS = float(GalaxyTile.SUN_RADIUS)
	BORDER_MARGIN = SUN_RADIUS + 0.5
	MIN_DIST = 2.0 * SUN_RADIUS + 0.6

	print("🌌 Grille générée avec seed:", _world_seed)

	# Bruit
	noise.seed = _world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = NOISE_FREQ

	_spatial.clear()

	# 1) Restaurer caméra si on a GameState
	_restore_camera_state()

	# 2) Restaurer tuiles découvertes si disponibles
	if not _restore_discovered_tiles():
		# Sinon, grille de départ standard
		_generate_initial_grid()
		# Et si on a GameState, on l’informe de ces tuiles initiales
		_record_initial_tiles_to_state()

	_update_debug()

func _process(delta: float) -> void:
	_handle_pan(delta)
	_update_hover()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_zoom_in"):
		_zoom_in()
	elif event.is_action_pressed("ui_zoom_out"):
		_zoom_out()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Sécurité : fenêtre focus + souris dans le viewport
		var win: Window = get_window()
		if win == null or not win.has_focus():
			return
		var vp: Viewport = get_viewport()
		var mouse_vp: Vector2 = vp.get_mouse_position()
		if not Rect2(Vector2.ZERO, vp.get_visible_rect().size).has_point(mouse_vp):
			return

		var world_pos: Vector2 = get_global_mouse_position()

		# 1) clic sur un soleil → recentrer
		if _focus_camera_if_sun(world_pos):
			return

		# 2) sinon expansion
		_try_expand_from_click(world_pos)

# ------------------------------------------------------------------
# Caméra & debug
# ------------------------------------------------------------------
func _handle_pan(delta: float) -> void:
	var input_vec: Vector2 = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	).normalized()
	if input_vec != Vector2.ZERO:
		camera.position += input_vec * camera_speed * delta
		_persist_camera_state()
		_update_debug()

func _zoom_in() -> void:
	if current_zoom_index < zoom_levels.size() - 1:
		current_zoom_index += 1
		camera.zoom = Vector2.ONE * zoom_levels[current_zoom_index]
		_persist_camera_state()
		_update_debug()

func _zoom_out() -> void:
	if current_zoom_index > 0:
		current_zoom_index -= 1
		camera.zoom = Vector2.ONE * zoom_levels[current_zoom_index]
		_persist_camera_state()
		_update_debug()

func _update_debug() -> void:
	if debug_label == null:
		return
	var cam_tile: Vector2i = world_to_tile(camera.position)
	debug_label.text = "Pos: %s\nZoom: x%.1f\nTile: %s\nTiles générées: %d\n%s" % [
		"%s" % camera.position,
		zoom_levels[current_zoom_index],
		"%s" % cam_tile,
		generated_tiles.size(),
		last_click_info
	]

# ------------------------------------------------------------------
# Helpers grille & tuiles
# ------------------------------------------------------------------
func world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / TILE_SIZE), floor(pos.y / TILE_SIZE))

func tile_to_bounds(tile: Vector2i) -> Rect2:
	var origin: Vector2 = Vector2(tile) * float(TILE_SIZE)
	return Rect2(origin, Vector2(TILE_SIZE, TILE_SIZE))

func _generate_initial_grid() -> void:
	for tx in range(-START_RADIUS, START_RADIUS + 1):
		for ty in range(-START_RADIUS, START_RADIUS + 1):
			_generate_tile(Vector2i(tx, ty), START_COLOR)

func _generate_tile(tile_coords: Vector2i, color: Color) -> void:
	if generated_tiles.has(tile_coords):
		return

	var tile := GalaxyTile.new(tile_coords.x, tile_coords.y, TILE_SIZE, color)
	add_child(tile)
	generated_tiles[tile_coords] = tile

	# densité → alpha
	var density: float = _tile_density(tile_coords)    # [0..1]
	tile.set_fill_alpha(lerp(FILL_MIN, FILL_MAX, density))

	# échantillonnage continu (déterministe) avec raréfaction
	var suns_world: Array[Vector2] = _sample_tile_world(tile_coords, density)
	# conversion en coordonnées locales pour la tuile
	var local: Array[Vector2] = []
	var origin: Vector2 = Vector2(tile_coords) * float(TILE_SIZE)
	for p in suns_world:
		local.append(p - origin)
	tile.set_suns_local(local)

func _generate_neighbors(center: Vector2i, color: Color) -> void:
	for x in range(center.x - 1, center.x + 2):
		for y in range(center.y - 1, center.y + 2):
			_generate_tile(Vector2i(x, y), color)

# --- Adjacence en 8-voisins ---
func _is_adjacent_to_generated(coords: Vector2i) -> bool:
	if generated_tiles.has(coords):
		return true
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var n: Vector2i = coords + Vector2i(dx, dy)
			if generated_tiles.has(n):
				return true
	return false

func _try_expand_from_click(world_pos: Vector2) -> void:
	var tc: Vector2i = world_to_tile(world_pos)
	if generated_tiles.has(tc):
		_generate_neighbors(tc, DISCOVER_COLOR)
		_record_discovered_for(tc)
		last_click_info = "Clic %s → OK (tuile existante)" % tc
	elif _is_adjacent_to_generated(tc):
		_generate_neighbors(tc, DISCOVER_COLOR)
		_record_discovered_for(tc)
		last_click_info = "Clic %s → OK (adjacente 8-voisins)" % tc
	else:
		last_click_info = "Clic %s → refusé (hors frontière)" % tc
	_update_debug()

# ------------------------------------------------------------------
# Survol & centrage
# ------------------------------------------------------------------
func _update_hover() -> void:
	var win: Window = get_window()
	if win == null or not win.has_focus():
		return

	var vp: Viewport = get_viewport()
	var mouse_vp: Vector2 = vp.get_mouse_position()
	if not Rect2(Vector2.ZERO, vp.get_visible_rect().size).has_point(mouse_vp):
		if _hover_tile != null:
			_hover_tile.clear_hover()
			_hover_tile = null
			_hover_id = -1
		return

	var world_pos: Vector2 = get_global_mouse_position()
	var tc: Vector2i = world_to_tile(world_pos)

	var hit_tile: Node2D = null
	var hit_id: int = -1

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var neigh: Vector2i = tc + Vector2i(dx, dy)
			if not generated_tiles.has(neigh):
				continue
			var t: Node2D = generated_tiles[neigh]
			var id: int = t.get_sun_at_world_pos(world_pos)
			if id != -1:
				hit_tile = t
				hit_id = id
				break
		if hit_id != -1:
			break

	if hit_id != -1:
		if _hover_tile != null and _hover_tile != hit_tile:
			_hover_tile.clear_hover()
		_hover_tile = hit_tile
		_hover_id = hit_id
		if _hover_tile != null:
			_hover_tile.set_hovered_sun(_hover_id)
	else:
		if _hover_tile != null:
			_hover_tile.clear_hover()
			_hover_tile = null
			_hover_id = -1

# clic : focus caméra si un soleil est sous la souris
func _focus_camera_if_sun(world_pos: Vector2) -> bool:
	var tc: Vector2i = world_to_tile(world_pos)

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var neigh: Vector2i = tc + Vector2i(dx, dy)
			if not generated_tiles.has(neigh):
				continue
			var t: Node2D = generated_tiles[neigh]
			var id: int = t.get_sun_at_world_pos(world_pos)
			if id != -1:
				var p: Vector2 = t.get_sun_world_pos(id)
				camera.position = p  # tweenable plus tard
				_persist_camera_state()

				if _hover_tile != null and _hover_tile != t:
					_hover_tile.clear_hover()
				_hover_tile = t
				_hover_id = id
				t.set_hovered_sun(id)

				last_click_info = "Focus soleil #%d @ tuile %s" % [id, "%s" % neigh]
				_update_debug()
				return true

	return false

# ------------------------------------------------------------------
# Bruit / Densité
# ------------------------------------------------------------------
func _tile_density(coords: Vector2i) -> float:
	var n: float = noise.get_noise_2d(float(coords.x), float(coords.y))
	return clamp((n + 1.0) * 0.5, 0.0, 1.0)

# ------------------------------------------------------------------
# Sampling continu (déterministe)
# ------------------------------------------------------------------
# centre à l'intérieur de la tuile avec marge
func _inside_tile_with_margin(p_world: Vector2, tc: Vector2i) -> bool:
	var o: Vector2 = Vector2(tc) * float(TILE_SIZE)
	return (
		p_world.x > o.x + BORDER_MARGIN
		and p_world.x < o.x + float(TILE_SIZE) - BORDER_MARGIN
		and p_world.y > o.y + BORDER_MARGIN
		and p_world.y < o.y + float(TILE_SIZE) - BORDER_MARGIN
	)

# cellule de spatial hash (taille = MIN_DIST)
func _cell_of(p_world: Vector2) -> Vector2i:
	return Vector2i(floor(p_world.x / MIN_DIST), floor(p_world.y / MIN_DIST))

func _spatial_too_close(p_world: Vector2, min_d: float) -> bool:
	var c: Vector2i = _cell_of(p_world)
	var min2: float = min_d * min_d
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var n: Vector2i = Vector2i(c.x + dx, c.y + dy)
			if not _spatial.has(n):
				continue
			var arr: Array = _spatial[n]
			for q in arr:
				var qv: Vector2 = q
				if p_world.distance_squared_to(qv) < min2:
					return true
	return false

func _spatial_add(p_world: Vector2) -> void:
	var c: Vector2i = _cell_of(p_world)
	var arr: Array = _spatial.get(c, [])
	arr.append(p_world)
	_spatial[c] = arr

# seed stable par tuile
func _tile_seed(tc: Vector2i) -> int:
	# mélange simple avec la seed de monde
	var h: int = int(((tc.x & 0xFFFF) << 16) ^ (tc.y & 0xFFFF) ^ (_world_seed & 0x7FFFFFFF))
	if h == 0:
		h = 1
	return h

# renvoie des positions MONDE acceptées pour la tuile
func _sample_tile_world(tc: Vector2i, density: float) -> Array[Vector2]:
	var accepted: Array[Vector2] = []

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _tile_seed(tc)

	# proba réduite : densité * scale
	var prob: float = clamp(density * DENSITY_SCALE, 0.0, 1.0)

	var origin: Vector2 = Vector2(tc) * float(TILE_SIZE)

	for gx in range(0, TILE_SIZE, CANDIDATE_STEP):
		for gy in range(0, TILE_SIZE, CANDIDATE_STEP):
			# centre de cellule + jitter
			var base: Vector2 = origin + Vector2(gx + CANDIDATE_STEP * 0.5, gy + CANDIDATE_STEP * 0.5)
			var p: Vector2 = base + Vector2(
				rng.randf_range(-CANDIDATE_JITTER, CANDIDATE_JITTER),
				rng.randf_range(-CANDIDATE_JITTER, CANDIDATE_JITTER)
			)

			# 0) marge anti-bord
			if not _inside_tile_with_margin(p, tc):
				continue
			# 1) proba densité
			if rng.randf() >= prob:
				continue
			# 2) min-dist global
			if _spatial_too_close(p, MIN_DIST):
				continue

			_spatial_add(p)
			accepted.append(p)

			if accepted.size() >= MAX_SUNS_PER_TILE:
				# plafonnement local : on garde les premiers
				pass

	return accepted

# ------------------------------------------------------------------
# Persistance via GameState
# ------------------------------------------------------------------
func _restore_discovered_tiles() -> bool:
	if _gs == null:
		return false
	if not _gs.has_method("get_discovered_tiles"):
		return false

	var tiles: Array = _gs.call("get_discovered_tiles")
	if tiles.is_empty():
		return false

	# Générer uniquement ce qui est marqué comme découvert
	for t in tiles:
		if t is Vector2i:
			_generate_tile(t, START_COLOR)
		elif t is Array and t.size() >= 2:
			var vx: int = int(t[0])
			var vy: int = int(t[1])
			_generate_tile(Vector2i(vx, vy), START_COLOR)

	return true

func _record_initial_tiles_to_state() -> void:
	if _gs == null:
		return
	if not _gs.has_method("add_discovered_tile"):
		return
	# carré initial autour de (0,0)
	for tx in range(-START_RADIUS, START_RADIUS + 1):
		for ty in range(-START_RADIUS, START_RADIUS + 1):
			_add_tile_to_state(Vector2i(tx, ty))

func _record_discovered_for(center: Vector2i) -> void:
	if _gs == null:
		return
	for x in range(center.x - 1, center.x + 2):
		for y in range(center.y - 1, center.y + 2):
			_add_tile_to_state(Vector2i(x, y))

func _add_tile_to_state(tc: Vector2i) -> void:
	if _gs == null:
		return
	# has_discovered_tile(tx,ty) → bool
	if _gs.has_method("has_discovered_tile") and _gs.has_method("add_discovered_tile"):
		var has: bool = bool(_gs.call("has_discovered_tile", tc.x, tc.y))
		if not has:
			_gs.call("add_discovered_tile", tc.x, tc.y)

func _persist_camera_state() -> void:
	if _gs == null:
		return
	if _gs.has_method("set_galaxy_camera_state"):
		_gs.call("set_galaxy_camera_state", camera.position, current_zoom_index)

func _restore_camera_state() -> void:
	if _gs == null:
		return
	if not _gs.has_method("get_galaxy_camera_state"):
		return

	var st: Dictionary = _gs.call("get_galaxy_camera_state")
	# st = { "pos": Vector2, "zoom_index": int }
	if st.has("pos"):
		var pos: Vector2 = st["pos"]
		camera.position = pos
	if st.has("zoom_index"):
		var zi: int = int(st["zoom_index"])
		zi = clamp(zi, 0, zoom_levels.size() - 1)
		current_zoom_index = zi
		camera.zoom = Vector2.ONE * zoom_levels[current_zoom_index]
