extends Node2D

class_name BaseScene

onready var _player = $Player
onready var _grapnel = $Grapnel
onready var _camera = $Camera


func _ready():
	_player.set_grapnel(_grapnel)
	_grapnel.set_player(_player)


func _process(_delta):
	_camera.position = _player.position
