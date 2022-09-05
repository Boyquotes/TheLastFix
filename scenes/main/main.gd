extends Node2D

class_name Main


onready var _camera = $Camera
onready var _level_container = $LevelContainer
onready var _level_view = $LevelView
onready var _dialogue_box = $DialogueBox
onready var _speaker_picture = $DialogueBox/SpeakerPicture
onready var _speaker_label = $DialogueBox/SpeakerLabel
onready var _dialogue_label = $DialogueBox/Dialogue

var _current_level = null
var _current_level_instance = null
var _current_dialogue = ""
var _dialogue_parser = Dialogue.new()


func _ready():
	_dialogue_parser.parse()
	load_level(load("res://scenes/main_menu/main_menu.tscn"))


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


func set_dialogue_speaker(speaker: String):
	_speaker_label.text = speaker
	var picture = null
	match speaker:
		"Boss":
			picture = load("res://scenes/main_menu/phone.png")
	
	if picture == null:
		print("Error: Unknown speaker ", speaker)
		return
	
	_speaker_picture.texture = picture


func play_dialogue_sequence(_id: String):
	pass
	
