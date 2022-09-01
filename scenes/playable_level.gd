extends Level

class_name PlayableLevel

onready var _player = $Player
onready var _grapnel = $Grapnel
onready var _camera = $Camera


func _ready():
	_player.set_grapnel(_grapnel)


func _process(_delta):
	_camera.position = _player.position
