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


func _process(delta):
	$Demo/ParallaxBackground.scroll_base_offset.x -= delta * 60
	
	if _started_cutscene:
		return


func play_intro():
	$CutsceneAnimator.play("start")
	_started_cutscene = true


func load_first_level():
	Game.load_gui(load("res://scenes/page_intro/page_intro.tscn"))
