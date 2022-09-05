extends Node2D

class_name Main


signal dialogue_ended


onready var _camera = $Camera
onready var _level_container = $LevelContainer
onready var _level_view = $LevelView
onready var _dialogue_box = $HUD/DialogueBox
onready var _speaker_picture = $HUD/DialogueBox/SpeakerPicture
onready var _speaker_label = $HUD/DialogueBox/SpeakerLabel
onready var _dialogue_label = $HUD/DialogueBox/Dialogue

var _current_level = null
var _current_level_instance = null
var dialogue = Dialogue.new()

var _current_node_index = 0
var _char_in_node_index = 0
var _current_line = null
var _action_end_paused = false

var _dialogue_time = -1.0
const _dialogue_speed = 0.025


func _ready():
	dialogue.parse()
	load_level(load("res://scenes/main_menu/main_menu.tscn"))


func _process(delta):
	if _dialogue_time >= 0:
		_dialogue_time += delta
		if _dialogue_time >= _dialogue_speed:
			_dialogue_time = 0
			advance_dialogue()

	if _action_end_paused and Input.is_action_just_pressed("grapple"):
		var action = dialogue.next_action()
		if action != null:
			execute_action(action)
		else:
			_dialogue_box.visible = false
			_action_end_paused = false
			emit_signal("dialogue_ended")


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


func play_dialogue_sequence(id: String):
	dialogue.load_sequence(id)
	execute_action(dialogue.next_action())
	_dialogue_box.visible = true


func execute_action(action):
	_action_end_paused = false
	if action is Dialogue.SpeakerAction:
		set_dialogue_speaker(action.name)
		execute_action(dialogue.next_action())
	elif action is Dialogue.LineAction:
		_dialogue_label.text = ""
		_current_line = action
		_current_node_index = 0
		_char_in_node_index = 0
		_dialogue_time = 0


func advance_dialogue():
	var node = _current_line.nodes[_current_node_index]
	if node is Dialogue.TextNode:
		_dialogue_label.text += node.content[_char_in_node_index]

	_char_in_node_index += 1
	if _char_in_node_index >= node.length:
		_char_in_node_index = 0
		_current_node_index += 1
		if _current_node_index >= _current_line.nodes.size():
			_action_end_paused = true
			_dialogue_time = -1
			return
