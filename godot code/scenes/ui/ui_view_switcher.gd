extends Control
class_name UiViewSwitcher

@export var game_mode_path: NodePath

@onready var _gm: Node = _resolve_gamemode()
@onready var _btn_galaxy: Button = %BtnGalaxy
@onready var _btn_system: Button = %BtnSystem
@onready var _btn_planet: Button = %BtnPlanet

func _ready() -> void:
	_connect_buttons()
	_update_selected_visual()

func _resolve_gamemode() -> Node:
	# 1) Autoload prioritaire : GameModeAuto (corrigé), puis GameMode (fallback)
	var auto = get_node_or_null("/root/GameModeAuto") # <-- FIX ICI
	if auto != null:
		return auto
	auto = get_node_or_null("/root/GameMode")
	if auto != null:
		return auto
	# 2) Sinon, NodePath exporté si tu veux lier manuellement
	if game_mode_path != NodePath(""):
		var n = get_node_or_null(game_mode_path)
		if n != null:
			return n
	# 3) Dernier recours : cherche un node nommé GameMode dans la scène
	if get_tree().current_scene:
		return get_tree().current_scene.find_child("GameMode", true, false)
	return null

func _connect_buttons() -> void:
	_btn_galaxy.pressed.connect(_on_galaxy)
	_btn_system.pressed.connect(_on_system)
	_btn_planet.pressed.connect(_on_planet)

func _on_galaxy() -> void:
	if _gm and _gm.has_method("go_to_galaxy"):
		_gm.call("go_to_galaxy")
	_update_selected_visual("galaxy")

func _on_system() -> void:
	print("[UI] click SYSTEM  gm=", _gm)
	if _gm == null:
		push_error("UiViewSwitcher: GameMode introuvable (vérifie l’autoload 'GameModeAuto').")
		return
	if _gm.has_method("go_to_system"):
		_gm.call("go_to_system")
	else:
		push_error("UiViewSwitcher: 'go_to_system' manquant sur " + str(_gm))
	_update_selected_visual("system")

func _on_planet() -> void:
	if _gm and _gm.has_method("go_to_planet"):
		_gm.call("go_to_planet")
	_update_selected_visual("planet")

func _update_selected_visual(which: String = "") -> void:
	var map := {
		"galaxy": _btn_galaxy,
		"system": _btn_system,
		"planet": _btn_planet
	}
	for k in map.keys():
		var b: Button = map[k]
		b.disabled = (k == which) and which != ""
