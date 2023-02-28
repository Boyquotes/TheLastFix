extends GUIScene


func _ready():
	Game.load_level(preload("res://scenes/intro/intro.tscn"))
	if not Game.save_file_exists():
		$Menu.offset_top = -12
		$Menu/Continue.visible = false
		$Menu/NewGame.text = "Start"


func start_new_game():
	Game._current_level.play_intro()
	$Menu.visible = false
	Game.pausable = true


func try_game_load():
	var save = Game.get_save()
	if save.is_empty():
		return false

	Game.fade_out(0.3)
	var error = Game.connect("fade_finished", Callable(self, "load_game").bind(save), CONNECT_ONE_SHOT)
	assert(error == 0)
	return true


func load_game(save: Dictionary):
	await get_tree().process_frame
	Game.fade_in(0.3)
	Game.load_save(save)
	close()


func _on_submenu_option_pressed(option: String):
	match option:
		"Continue":
			if not try_game_load():
				start_new_game()
		"NewGame":
			start_new_game()
		"Settings":
			return
		"Exit":
			get_tree().quit()
	$Menu.enabled = false
