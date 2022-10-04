extends Level

var _started_cutscene = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$Demo/RoadAnimation.play("ride")
	$Demo/HeadAnimation.play("ride")
	$Demo/CarSwayAnimation.play("sway")
	$Demo/Car.play("default")
	$GUI/Start.play("default")


func _process(delta):
	$Demo/ParallaxBackground.scroll_base_offset.x -= delta * 40
	
	if Input.is_action_pressed("grapple") and not _started_cutscene:
		_cutscene_player.play("start")
		$GUI/Start.visible = false
		_started_cutscene = true


func load_first_level():
	Game.load_gui(load("res://scenes/page_intro/page_intro.tscn"))
