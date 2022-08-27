extends Node2D

onready var _player = $Player
onready var _grapnel = $Grapnel
onready var _camera = $Camera


func _ready():
	_player.set_grapnel(_grapnel)


func _process(delta):
	_camera.position = _player.position
