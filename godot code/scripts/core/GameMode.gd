extends Node
class_name GameMode

# -----------------------------
# Mode de jeu
# -----------------------------
enum Mode { SOLO, MULTI }

var current_mode: int = int(Mode.SOLO)
var current_seed: int = 0

# Optionnel : lie GameState via l’Inspecteur
@export var game_state_path: NodePath
var _gs: Node = null

# Vue courante (doit matcher GameState.View)
const VIEW_GALAXY := 0
const VIEW_SYSTEM := 1
const VIEW_PLANET := 2

# Chemins des scènes de vue
const SCENE_GALAXY := "res://scenes/views/galaxy/galaxy_view.tscn"
const SCENE_SYSTEM := "res://scenes/views/system/system_view.tscn"
const SCENE_PLANET := "res://scenes/views/planet/planet_view.tscn"

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

# ------------------------------------------------------------------
# Bootstrap
# ------------------------------------------------------------------
func _ready() -> void:
	_gs = _find_game_state()
	if _gs == null:
		push_error("GameMode: GameState introuvable. Renseigne 'game_state_path' ou ajoute GameState en autoload.")
		return

	# Seed -> sun_key si vide
	if _gs.has_method("get_sun_key") and _gs.has_method("set_sun_key"):
		var k: Dictionary = _gs.call("get_sun_key")
		if int(k.get("seed", 0)) == 0 and current_seed != 0:
			k["seed"] = current_seed
			_gs.call("set_sun_key", k)

func _find_game_state() -> Node:
	if game_state_path != NodePath(""):
		var n = get_node_or_null(game_state_path)
		if n != null:
			return n
	var auto = get_node_or_null("/root/GameState")
	if auto != null:
		return auto
	if get_tree().current_scene:
		var found = get_tree().current_scene.find_child("GameState", true, false)
		if found != null:
			return found
	return null

# ------------------------------------------------------------------
# Lancer une partie
# ------------------------------------------------------------------
func start_new_game(mode: int) -> void:
	current_mode = mode
	randomize()
	if mode == Mode.SOLO:
		current_seed = randi()
	else:
		current_seed = 123456789

	print("▶ Nouveau jeu - Mode:", current_mode, " Seed:", current_seed)
	_init_default_state_for_new_run()
	# démarre en vue galaxie
	_change_scene_safe(SCENE_GALAXY)

func _init_default_state_for_new_run() -> void:
	if _gs == null:
		return
	if _gs.has_method("set_current_view"):
		_gs.call("set_current_view", VIEW_GALAXY)
	if _gs.has_method("set_current_system_id"):
		_gs.call("set_current_system_id", 0)
	if _gs.has_method("get_sun_key") and _gs.has_method("set_sun_key"):
		var k: Dictionary = _gs.call("get_sun_key")
		k["seed"] = current_seed
		_gs.call("set_sun_key", k)

# ------------------------------------------------------------------
# Sauvegarde / Chargement
# ------------------------------------------------------------------
func save_game(player_data: Dictionary = {}) -> void:
	var state_dict: Dictionary = {}
	if _gs != null and _gs.has_method("to_dict"):
		state_dict = _gs.call("to_dict")

	var payload := {
		"version": SAVE_VERSION,
		"mode": int(current_mode),
		"seed": current_seed,
		"state": state_dict,
		"player": player_data,
	}

	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload))
		f.close()
		print("💾 Sauvegarde effectuée →", SAVE_PATH)
	else:
		push_error("Impossible d'écrire la sauvegarde: " + SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_error("Pas de sauvegarde trouvée.")
		return

	var text: String = FileAccess.get_file_as_string(SAVE_PATH)
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		var dict := data as Dictionary
		current_mode = int(dict.get("mode", int(Mode.SOLO)))
		current_seed = int(dict.get("seed", 0))

		if _gs != null and _gs.has_method("from_dict") and dict.has("state") and dict["state"] is Dictionary:
			_gs.call("from_dict", dict["state"])

		print("▶ Partie chargée - Mode:", current_mode, " Seed:", current_seed)
	else:
		push_error("Fichier de sauvegarde invalide.")

# ------------------------------------------------------------------
# Navigation (appelées par l’UI)
# ------------------------------------------------------------------
func go_to_galaxy() -> void:
	print("[GM] go_to_galaxy")
	if _gs != null and _gs.has_method("set_current_view"):
		_gs.call("set_current_view", VIEW_GALAXY)
	_change_scene_safe(SCENE_GALAXY)

func go_to_system(system_id: int = -1) -> void:
	print("[GM] go_to_system", system_id)
	if _gs != null:
		if system_id >= 0 and _gs.has_method("set_current_system_id"):
			_gs.call("set_current_system_id", system_id)
		if _gs.has_method("set_current_view"):
			_gs.call("set_current_view", VIEW_SYSTEM)
	_change_scene_safe(SCENE_SYSTEM)

func go_to_planet() -> void:
	print("[GM] go_to_planet")
	if _gs != null and _gs.has_method("set_current_view"):
		_gs.call("set_current_view", VIEW_PLANET)
	_change_scene_safe(SCENE_PLANET)

# ------------------------------------------------------------------
# Utilitaire : changement de scène robuste
# ------------------------------------------------------------------
func _change_scene_safe(path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("[GameMode] Scène introuvable : " + path)
		return
	get_tree().change_scene_to_packed(packed)
