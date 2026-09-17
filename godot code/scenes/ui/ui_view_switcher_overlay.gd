# res://scripts/ui/view_switcher_overlay.gd
extends CanvasLayer

const UI_SWITCHER_SCENE := preload("res://scenes/ui/ui_view_switcher.tscn")
const VISIBLE_SCENES := ["GalaxyView", "SystemView", "PlanetView"]

var _ui: Control

func _ready() -> void:
	if get_node_or_null("UiViewSwitcher") == null:
		_ui = UI_SWITCHER_SCENE.instantiate()
		_ui.name = "UiViewSwitcher"
		add_child(_ui)
	layer = 100

	_refresh_visibility()
	if get_tree().has_signal("current_scene_changed"):
		get_tree().current_scene_changed.connect(_on_scene_changed)
	else:
		set_process(true)

func _process(_delta: float) -> void:
	if not get_tree().has_signal("current_scene_changed"):
		_refresh_visibility()

func _on_scene_changed() -> void:
	_refresh_visibility()

func _refresh_visibility() -> void:
	var cs := get_tree().current_scene
	var ok := cs != null and VISIBLE_SCENES.has(cs.name)
	visible = ok
