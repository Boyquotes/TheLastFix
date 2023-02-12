extends Level


func _ready():
	Game.set_zoom(1)
	Game.fade_in(0.5)


func _process(_delta):
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("escape"):
		Game.fade_out(0.5)
		var error = Game.connect("fade_finished",Callable(Game,"load_level").bind(load("res://scenes/main_menu/main_menu.tscn")),CONNECT_ONE_SHOT)
		assert(error == 0) #,"Error connecting fade_finished: " + str(error))
