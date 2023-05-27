extends VBoxContainer

class_name Submenu

signal option_pressed(name)
signal back

@onready var original_parent = get_parent()
var current_option


func exit():
	pass


func choose():
	emit_signal("option_pressed", current_option)
	return true
