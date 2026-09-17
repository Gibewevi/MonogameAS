extends Node

# --- Vues de haut niveau (navigation) ---
enum View { GALAXY, SYSTEM, PLANET }

# --- État courant ---
var current_view: View = View.GALAXY
var current_system_id: int = 0

# Clé compacte pour identifier un soleil (repro fixe entre vues).
# - seed     : seed RNG pour le soleil
# - class_id : index palette (utilisé si celsus == 0)
# - celsus   : température K (si > 0, prime sur class_id)
# - size     : taille grille/texture actuelle (identité visuelle)
# - steps    : nb de tons de palette (2..4)
var sun_key: Dictionary = {
	"seed": 0,
	"class_id": 0,
	"celsus": 0,
	"size": 48,
	"steps": 4,
}

# --- Persistance carte galaxie (session + sauvegarde) --------------------------
var discovered_tiles: Array[Vector2i] = []     # tuiles déjà générées/explorées
var _tile_index: Dictionary = {}               # "tx,ty" -> true (pour l’unicité)

var galaxy_camera_pos: Vector2 = Vector2.ZERO  # dernière position caméra
var galaxy_zoom_index: int = 0                 # dernier niveau de zoom (int)

# --- Signals (pour le HUD / contrôleurs) ---
signal view_changed(new_view: View)
signal system_changed(system_id: int)
signal sun_key_changed(new_key: Dictionary)
signal tiles_changed()

# --- Setters sûrs -------------------------------------------------------------

func set_current_view(v: View) -> void:
	if v == current_view:
		return
	current_view = v
	emit_signal("view_changed", current_view)

func set_current_system_id(id: int) -> void:
	if id == current_system_id:
		return
	current_system_id = id
	emit_signal("system_changed", current_system_id)

func set_sun_key(key: Dictionary) -> void:
	# Normalisation minimale et valeurs par défaut
	var k: Dictionary = {
		"seed": int(key.get("seed", sun_key["seed"])),
		"class_id": int(key.get("class_id", sun_key["class_id"])),
		"celsus": int(key.get("celsus", sun_key["celsus"])),
		"size": int(key.get("size", sun_key["size"])),
		"steps": clamp(int(key.get("steps", sun_key["steps"])), 2, 4),
	}
	# Rien à faire si inchangé
	if k.hash() == sun_key.hash():
		return
	sun_key = k
	emit_signal("sun_key_changed", sun_key)

# --- Helpers d’accès ----------------------------------------------------------

func get_sun_key() -> Dictionary:
	# Retourne une copie pour éviter les mutations silencieuses
	return {
		"seed": sun_key["seed"],
		"class_id": sun_key["class_id"],
		"celsus": sun_key["celsus"],
		"size": sun_key["size"],
		"steps": sun_key["steps"],
	}

func is_using_temperature() -> bool:
	return int(sun_key.get("celsus", 0)) > 0

# --- Persistance des tuiles ---------------------------------------------------

func _tile_key(tx:int, ty:int) -> String:
	return str(tx, ",", ty)

func has_discovered_tile(tx:int, ty:int) -> bool:
	return _tile_index.has(_tile_key(tx, ty))

func add_discovered_tile(tx:int, ty:int) -> void:
	var k := _tile_key(tx, ty)
	if _tile_index.has(k):
		return
	_tile_index[k] = true
	discovered_tiles.append(Vector2i(tx, ty))
	emit_signal("tiles_changed")

func add_discovered_tiles(list:Array) -> void:
	for v in list:
		if v is Vector2i:
			add_discovered_tile(v.x, v.y)
		elif v is Array and v.size() >= 2:
			add_discovered_tile(int(v[0]), int(v[1]))

func get_discovered_tiles() -> Array[Vector2i]:
	return discovered_tiles.duplicate()

func clear_discovered_tiles() -> void:
	discovered_tiles.clear()
	_tile_index.clear()
	emit_signal("tiles_changed")

# Helper pratique si tu veux peupler un carré initial depuis GalaxyView
func ensure_initial_tiles(cx:int=0, cy:int=0, radius:int=1) -> void:
	if discovered_tiles.size() > 0:
		return
	for tx in range(cx - radius, cx + radius + 1):
		for ty in range(cy - radius, cy + radius + 1):
			add_discovered_tile(tx, ty)

# --- État caméra galaxie ------------------------------------------------------

func set_galaxy_camera_state(pos:Vector2, zoom_idx:int) -> void:
	galaxy_camera_pos = pos
	galaxy_zoom_index = zoom_idx

func get_galaxy_camera_state() -> Dictionary:
	return { "pos": galaxy_camera_pos, "zoom_index": galaxy_zoom_index }

# --- (Dé)sérialisation légère pour GameMode -----------------------------------

func _pack_tiles() -> Array:
	var out: Array = []
	for v in discovered_tiles:
		out.append([v.x, v.y])
	return out

func _unpack_tiles(arr:Array) -> void:
	clear_discovered_tiles()
	for a in arr:
		if a is Array and a.size() >= 2:
			add_discovered_tile(int(a[0]), int(a[1]))

func to_dict() -> Dictionary:
	return {
		"view": int(current_view),
		"system_id": current_system_id,
		"sun_key": get_sun_key(),
		"discovered_tiles": _pack_tiles(),
		"galaxy_cam": [galaxy_camera_pos.x, galaxy_camera_pos.y],
		"galaxy_zoom_index": galaxy_zoom_index,
	}

func from_dict(d: Dictionary) -> void:
	set_current_view(int(d.get("view", int(View.GALAXY))))
	set_current_system_id(int(d.get("system_id", 0)))
	set_sun_key(d.get("sun_key", sun_key))

	var tiles = d.get("discovered_tiles", [])
	if tiles is Array:
		_unpack_tiles(tiles)

	var cam = d.get("galaxy_cam", null)
	if cam is Array and cam.size() >= 2:
		galaxy_camera_pos = Vector2(float(cam[0]), float(cam[1]))
	else:
		galaxy_camera_pos = Vector2.ZERO

	galaxy_zoom_index = int(d.get("galaxy_zoom_index", 0))
