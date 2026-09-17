@tool
extends EditorPlugin

const NINE_PATCH_BUTTON : String = "NinePatchButton"


func _enter_tree():
	add_custom_type( NINE_PATCH_BUTTON, "Button", preload( "nine_patch_button.gd" ), preload( "icon.png" ) )


func _exit_tree():
	remove_custom_type( NINE_PATCH_BUTTON )
