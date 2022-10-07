extends Node2D

class_name Main

signal fade_finished


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

var fade_level = 1
var fade_speed = 0
var fade_enabled = true


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


func _process(delta):
	if _current_gui == null and pausable and Input.is_action_just_pressed("escape"):
		load_gui(preload("res://scenes/pause/pause.tscn"))

	if fade_enabled and fade_speed != 0:
		fade_level += fade_speed * delta
		if fade_speed > 0 and fade_level >= 1:
			fade_level = 1
			fade_speed = 0
			emit_signal("fade_finished")
		elif fade_speed < 0 and fade_level <= 0:
			fade_level = 0
			fade_speed = 0
			emit_signal("fade_finished")
		
		_level_view.modulate = Color(fade_level, fade_level, fade_level)


func fade_in(time: float):
	fade_speed = max((1 - fade_level) / time, 0.001)


func fade_out(time: float):
	fade_speed = -max(fade_level / time, 0.001)
	

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


func get_save():
	var save_file = File.new()
	if not save_file.file_exists(save_path):
		return null

	save_file.open(save_path, File.READ)
	var save_data: Dictionary = parse_json(save_file.get_as_text())
	save_file.close()
	return save_data


func load_save(save: Dictionary):
	var level_path = save['level']
	load_level(load(level_path), false)
	_current_level.end_cutscenes = save['end_cutscenes']
	_current_level.start_at_screen = save['screen']
	_current_level.start_at_spawn = str2var("Vector2" + save['spawn'])
	_level_container.add_child(_current_level)
	Game.pausable = true
