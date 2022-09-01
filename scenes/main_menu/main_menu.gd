extends Level


# Called when the node enters the scene tree for the first time.
func _ready():
	$Demo/RoadAnimation.play("ride")
	$Demo/HeadAnimation.play("ride")
	$Demo/CarSwayAnimation.play("sway")
	$Demo/Car.play("default")
	$GUI/Start.play("default")



func _process(delta):
	$Demo/ParallaxBackground.scroll_base_offset.x -= delta * 40
	
	if Input.is_action_pressed("grapple"):
		$StartupAnimation.play("start")

func load_first_level():
	game.load_level(load("res://scenes/test/test.tscn"))
