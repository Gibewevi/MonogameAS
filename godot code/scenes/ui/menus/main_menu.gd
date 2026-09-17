extends Control

func _on_start_button_pressed() -> void:
	var planet_scene = load("res://scenes/views/planet_view.tscn")
	get_tree().change_scene_to_packed(planet_scene)

func _on_options_button_pressed() -> void:
	$Panel/MainMenuBox.visible = false
	$Panel/OptionsMenuBox.visible = true
	$Panel.custom_minimum_size = Vector2(500, 400)

func _on_back_button_pressed() -> void:
	$Panel/MainMenuBox.visible = true
	$Panel/OptionsMenuBox.visible = false
	$Panel.custom_minimum_size = Vector2(300, 200)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
