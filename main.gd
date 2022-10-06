extends Node2D

class_name Main


onready var _camera = $Camera
onready var _level_container = $LevelContainer
onready var _level_view = $LevelView
onready var _hud = $HUD


var _current_level = null
var _current_gui = null
onready var _dialogue = $HUD/DialogueBox

export var pausable = true


func _ready():
	var root = get_tree().root
	_current_level = root.get_child(root.get_child_count() - 1)
	root.call_deferred("remove_child", _current_level)
	if _current_level is Level:
		_level_container.call_deferred("add_child", _current_level)
	elif _current_level is GUIScene:
		_hud.call_deferred("add_child", _current_level)
		_current_gui = _current_level
		_current_level = null

	_camera.set_deferred("current", true)


func _process(_delta):
	if _current_gui == null and pausable and Input.is_action_just_pressed("escape"):
		get_tree().paused = true
		load_gui(preload("res://scenes/pause/pause.tscn"))


func load_level(level: Resource):
	if _current_level != null:
		_level_container.remove_child(_current_level)
		_current_level.call_deferred("free")

	_current_level = level.instance()
	_level_container.add_child(_current_level)


func load_gui(gui: Resource):
	_current_gui = gui.instance()
	_hud.add_child(_current_gui)
	return _current_gui


func unload_gui():
	_hud.remove_child(_current_gui)
	_current_gui = null


func get_camera() -> Camera2D:
	return _camera


func get_view() -> Sprite:
	return _level_view


func get_player():
	if _current_level is PlayableLevel:
		return _current_level.get_player()
	return null


func get_dialogue() -> Dialogue:
	return _dialogue
