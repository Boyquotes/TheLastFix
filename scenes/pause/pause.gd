extends GUIScene


var prog = 0
var dir = 1

var _fade_speed = 5

var _quitting = false

@onready var menu = $Box/Container/Menu


func _ready():
	get_tree().paused = true
	Game.fade_enabled = false
	Game.zoom_enabled = false
	modulate = Color(1, 1, 1, 0)


func _process(delta):
	if prog < 1 and dir > 0:
		prog += delta * _fade_speed
		if prog >= 1:
			prog = 1
			dir = 0
	elif prog > 0 and dir < 0:
		prog -= delta * _fade_speed
		if prog <= 0:
			prog = 0
			if _quitting:
				Game.fade_in(1.0 / _fade_speed)
				Game.load_level(preload("res://scenes/main_menu/main_menu.tscn"))
				Game.get_dialogue().clear()
			Game.fade_enabled = true
			Game.zoom_enabled = true
			get_tree().paused = false
			Game.unload_gui()
			

	modulate = Color(1, 1, 1, prog)
	
	if Input.is_action_just_pressed("escape"):
		dir = -1

	menu.enabled = dir >= 0


func _on_submenu_option_pressed(option):
	match option:
		"Resume":
			dir = -1
		"Quit":
			Game.save_game()
			Game.fade_enabled = true
			Game.fade_out(1.0 / _fade_speed)
			_quitting = true
			dir = -1
