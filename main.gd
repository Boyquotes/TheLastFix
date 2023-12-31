extends Node2D

class_name Main

signal fade_finished
signal zoom_finished
signal player_light_changed(player_energy, grapnel_energy)


@onready var _camera = $Camera
@onready var _level_container = $LevelContainer
@onready var _level_view = $LevelView
@onready var _hud = $HUD

const SAVE_PATH = "user://save.json"


var _current_level: Level
var _last_loaded_level: Resource
@onready var _dialogue = $HUD/DialogueBox

@export var pausable = true

var fade_level = 1.0
var fade_speed = 0.0
var fade_enabled = true
var zoom_enabled = true

var zoom_center = Vector2.ZERO
var prev_zoom_center = Vector2.ZERO
var zoom_prog = 0.0
var zoom_origin = 1.0
var zoom_target = 1.0
var zoom_speed = 0.0

@onready var Settings = $Settings


func _ready():
	randomize()
	var root = get_tree().root

	var level = root.get_child(0)
	if level == self:
		level = root.get_child(1)

	if level is Level:
		level.call_deferred("reparent", _level_container)
		_current_level = level
	elif level is GUIScene:
		level.call_deferred("reparent", _hud)


func _process(delta):
	if pausable and Input.is_action_just_pressed("escape"):
		pausable = false
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
		for child in _hud.get_children():
			if child is GUIScene and child.allow_fade:
				child.modulate = _level_view.modulate

	if zoom_enabled and zoom_speed != 0:
		zoom_prog += zoom_speed * delta
		if zoom_speed > 0 and zoom_prog >= 1:
			zoom_prog = 1
			zoom_speed = 0
			emit_signal("zoom_finished")
		
		var level = smoothstep(0, 1, zoom_prog)
		var strength = lerp(zoom_origin, zoom_target, level)
		_camera.zoom = Vector2(1 / strength, 1 / strength)
		_camera.offset = lerp((1 - zoom_origin) * prev_zoom_center, (1 - zoom_target) * zoom_center, level)


func fade_in(time: float):
	fade_speed = max((1 - fade_level) / time, 0.001)


func fade_out(time: float):
	fade_speed = -max(fade_level / time, 0.001)


func zoom_in(time: float, level: float, center: Vector2 = Vector2(-1, -1)):
	zoom_origin = zoom_target
	zoom_target = level
	zoom_prog = 0
	prev_zoom_center = zoom_center
	if center != Vector2(-1, -1):
		zoom_center = center - _current_level.camera.get_screen_center_position()
	zoom_speed = 1 / time


func zoom_out(time: float, level: float = 1.0):
	zoom_origin = zoom_target
	zoom_target = level
	zoom_prog = 0
	zoom_speed = 1 / time
	prev_zoom_center = zoom_center


func set_zoom(level: float, center: Vector2 = Vector2(-1, -1)):
	prev_zoom_center = zoom_center
	if center != Vector2(-1, -1):
		zoom_center = center - _current_level.camera.get_screen_center_position()

	_camera.zoom = Vector2(1, 1) / level
	_camera.offset = (1 - level) * zoom_center
	zoom_target = level
	zoom_speed = 0
	zoom_prog = 0


func set_player_light(player_energy: float, grapnel_energy: float = player_energy):
	emit_signal("player_light_changed", player_energy, grapnel_energy)


func load_level(level: Resource, start = true):
	_last_loaded_level = level
	if _current_level != null:
		_level_container.remove_child(_current_level)
		_current_level.call_deferred("free")

	_current_level = level.instantiate()
	if start:
		_level_container.add_child(_current_level)


func load_gui(gui: Resource):
	var scene = gui.instantiate()
	_hud.add_child(scene)
	return scene


func unload_gui(scene: GUIScene):
	_hud.remove_child(scene)


func clear_guis():
	for child in _hud.get_children():
		if child is GUIScene:
			_hud.remove_child(child)


func get_view() -> Sprite2D:
	return _level_view


func get_player() -> Player:
	if _current_level is PlayableLevel:
		return _current_level.get_player()
	return null


func get_dialogue() -> Dialogue:
	return _dialogue


func save_game():
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(_current_level.get_save_data()))


func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func get_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_conv = JSON.new()
	json_conv.parse(save_file.get_as_text())
	return json_conv.get_data()


func load_save(save: Dictionary):
	var level_path = save['level']
	load_level(load(level_path), false)
	_current_level.end_cutscenes = save['end_cutscenes']
	if save['screen'] != &'':
		_current_level.start_at_screen = _current_level.get_node(save['screen'])
	if save['screen'] != &'':
		_current_level.start_at_spawn = _current_level.get_node(save['spawn'])
	_level_container.add_child(_current_level)
	Game.pausable = true
