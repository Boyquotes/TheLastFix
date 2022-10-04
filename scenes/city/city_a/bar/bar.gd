extends Node2D

var _player: Player
onready var _screen = $".."
onready var _door_shadow = $DoorShadow


func _process(_delta):
	if _screen.active:
		if _player == null:
			_player = Game.get_player()
		_door_shadow.visible = _player.position.x > _door_shadow.global_position.x
		_door_shadow.global_scale.x = (_player.position.x - _door_shadow.global_position.x) / 20


func _on_Bar_Sign_finished_fixing():
	_screen.block_right = false
