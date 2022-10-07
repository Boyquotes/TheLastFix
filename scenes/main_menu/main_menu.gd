extends Level

var _started_cutscene = false


# Called when the node enters the scene tree for the first time.
func _ready():
	Game.pausable = false
	$Demo/RoadAnimation.play("ride")
	$Demo/HeadAnimation.play("ride")
	$Demo/CarSwayAnimation.play("sway")
	$Demo/Car.play("default")
	
	if not Game.save_file_exists():
		$GUI/Menu.margin_top = -12
		$GUI/Menu/Continue.visible = false
		$GUI/Menu/NewGame.text = "Start"


func _process(delta):
	$Demo/ParallaxBackground.scroll_base_offset.x -= delta * 40
	
	if _started_cutscene:
		return


func start_new_game():
	_cutscene_player.play("start")
	$GUI/Menu.visible = false
	_started_cutscene = true
	Game.pausable = true


func try_game_load():
	var save = Game.get_save()
	if save.empty():
		return false

	Game.fade_out(0.3)
	var error = Game.connect("fade_finished", self, "load_game", [save])
	if error != 0:
		print("Error connecting fade_finished: ", error)
	return true


func load_game(save: Dictionary):
	Game.disconnect("fade_finished", self, "load_game")
	yield(get_tree(), "idle_frame")
	Game.fade_in(0.3)
	Game.load_save(save)


func load_first_level():
	Game.load_gui(load("res://scenes/page_intro/page_intro.tscn"))


func _on_Menu_option_pressed(index):
	$GUI/Menu.enabled = false
	match index:
		0:
			if not try_game_load():
				start_new_game()
		1:
			start_new_game()
		2:
			get_tree().quit()
