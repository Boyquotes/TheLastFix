extends Level

class_name PlayableLevel

onready var _player = $Player
onready var _grapnel = $Grapnel

var _active_screen: Screen


func _ready():
	_player.set_grapnel(_grapnel)
	
	for node in get_children():
		if node is Screen:
			node.set_level(self)


func _process(_delta):
	_camera.position = _player.position


func set_active_screen(screen: Screen):
	if _active_screen != null:
		_active_screen.active = false

	_active_screen = screen
	screen.active = true
	_grapnel.retract()

	var limit = screen.get_extents()
	print("Switched to screen ", screen.name)

	_camera.limit_left = limit.position.x
	_camera.limit_top = limit.position.y
	_camera.limit_right = limit.end.x
	_camera.limit_bottom = limit.end.y
