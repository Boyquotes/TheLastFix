extends Level

var _started_cutscene = false


# Called when the node enters the scene tree for the first time.
func _ready():
	Game.pausable = false
	$Demo/RoadAnimation.play("ride")
	$Demo/HeadAnimation.play("ride")
	$Demo/CarSwayAnimation.play("sway")
	$Demo/Car.play("default")
	$GUI/Start.play("default")


func _process(delta):
	$Demo/ParallaxBackground.scroll_base_offset.x -= delta * 40
	
	if _started_cutscene:
		return

	if Input.is_action_just_pressed("interact") or (Input.is_action_just_pressed("load_tmp") and not try_game_load()):
		_cutscene_player.play("start")
		$GUI/Start.visible = false
		_started_cutscene = true
		Game.pausable = true


func try_game_load():
	var save = Game.get_save()
	if save == null or save.empty():
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
