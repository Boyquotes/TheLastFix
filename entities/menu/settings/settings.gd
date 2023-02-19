extends Submenu


func select_option(option: String):
	match option:
		"Back":
			emit_signal("back")
