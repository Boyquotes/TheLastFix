extends Node2D

class_name Main


onready var _camera = $Camera
onready var _level_container = $LevelContainer
onready var _level_view = $LevelView

var _current_level = null
var _current_level_instance = null


func _ready():
	load_level(load("res://scenes/city/city.tscn"))


func load_level(level: Resource):
	if _current_level != null:
		_level_container.remove_child(_current_level_instance)
		_current_level_instance.call_deferred("free")

	_current_level = level
	_current_level_instance = _current_level.instance()
	_current_level_instance.set_game(self)
	_level_container.add_child(_current_level_instance)


func reload_current_level():
	load_level(_current_level)


func get_camera() -> Camera2D:
	return _camera


func get_view() -> Sprite:
	return _level_view
