extends Node2D

onready var _player = $Player
onready var _camera = $Camera


func _process(delta):
	_camera.position = _player.position
