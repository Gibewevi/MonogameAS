extends VBoxContainer

const GALAXY_VIEW_PATH := "res://scenes/views/galaxy/galaxy_view.tscn"

func _ready() -> void:
	print("✅ Menu principal prêt")

# Récupère l'instance GameMode si l'autoload existe, sinon null
func _get_gamemode() -> Node:
	if has_node("/root/GameMode"):
		return get_node("/root/GameMode")
	return null

func _go_to_galaxy_view() -> void:
	var scene: PackedScene = load(GALAXY_VIEW_PATH)
	if scene:
		get_tree().change_scene_to_packed(scene)
	else:
		push_error("⚠️ Impossible de charger " + GALAXY_VIEW_PATH)

func _on_new_game_pressed() -> void:
	print("✅ Bouton New Game cliqué")
	var gm := _get_gamemode()
	if gm:
		# 0 == Mode.SOLO (on évite la dépendance de type ici)
		gm.call("start_new_game", 0)
	else:
		print("⚠️ GameMode non autoload → partie solo avec seed aléatoire.")
	_go_to_galaxy_view()

func _on_new_multi_button_pressed() -> void:
	var gm := _get_gamemode()
	if gm:
		# 1 == Mode.MULTI
		gm.call("start_new_game", 1)
	else:
		print("⚠️ GameMode non autoload, MULTI ignoré (solo temporaire).")
	_go_to_galaxy_view()

func _on_load_button_pressed() -> void:
	var gm := _get_gamemode()
	if gm:
		gm.call("load_game")
	else:
		print("⚠️ GameMode non autoload – impossible de charger.")
	_go_to_galaxy_view()
