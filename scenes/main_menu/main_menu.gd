extends Level

var _started_cutscene = false


func _ready():
	Game.pausable = false
	Game.set_zoom(1)
	Game.fade_in(0.5)
	$Demo/RoadAnimation.play("ride")
	$Demo/HeadAnimation.play("ride")
	$Demo/CarSwayAnimation.play("sway")
	$Demo/Car.play("default")
	
	if not Game.save_file_exists():
		$GUI/Menu.offset_top = -12
		$GUI/Menu/Continue.visible = false
		$GUI/Menu/NewGame.text = "Start"


func _process(delta):
	$Demo/ParallaxBackground.scroll_base_offset.x -= delta * 60
	
	if _started_cutscene:
		return


func start_new_game():
	$CutsceneAnimator.play("start")
	$GUI/Menu.visible = false
	_started_cutscene = true
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


func load_first_level():
	Game.load_gui(load("res://scenes/page_intro/page_intro.tscn"))


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
	$GUI/Menu.enabled = false
