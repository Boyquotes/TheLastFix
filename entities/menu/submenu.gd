extends VBoxContainer

class_name Submenu

signal option_pressed(name)
signal back;

var original_parent;

func _ready():
	original_parent = get_parent();


func select_option(option: String):
	emit_signal("option_pressed", option)
