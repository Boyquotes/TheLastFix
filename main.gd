extends Node2D

class_name Main


onready var _camera = $Camera
onready var _level_container = $LevelContainer
onready var _level_view = $LevelView
onready var _hud = $HUD

const save_path = "user://save.json"


var _current_level = null
var _last_loaded_level: Resource
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
		load_gui(preload("res://scenes/pause/pause.tscn"))


func load_level(level: Resource, start = true):
	_last_loaded_level = level
	if _current_level != null:
		_level_container.remove_child(_current_level)
		_current_level.call_deferred("free")

	_current_level = level.instance()
	if start:
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


func save_game():
	var save_file = File.new()
	save_file.open(save_path, File.WRITE)
	save_file.store_string(to_json(_current_level.get_save_data()))
	save_file.close()


func load_game():
	var save_file = File.new()
	save_file.open(save_path, File.READ)
	var save_data: Dictionary = parse_json(save_file.get_as_text())
	save_file.close()
	
	if save_data.empty():
		return false

	var level_path = save_data['level']
	load_level(load(level_path), false)
	_current_level.end_cutscenes = save_data['end_cutscenes']
	_current_level.start_at_screen = save_data['screen']
	_current_level.start_at_spawn = str2var("Vector2" + save_data['spawn'])
	_level_container.add_child(_current_level)
	Game.pausable = true
	return true
