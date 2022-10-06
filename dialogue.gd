extends Control

class_name Dialogue

signal paused
signal ended

var _current_node_index = 0
var _char_in_node_index = 0
var _current_line = null
var _action_end_paused = false

var _dialogue_time = -1.0
const _dialogue_speed = 0.025

var server = DialogueServer.new()

onready var _speaker_picture = $SpeakerPicture
onready var _speaker_label = $SpeakerLabel
onready var _dialogue_label = $Dialogue


func _ready():
	server.parse()


func _process(delta):
	if _dialogue_time >= 0:
		_dialogue_time += delta
		if _dialogue_time >= _dialogue_speed:
			_dialogue_time = 0
			advance()

	if _current_line != null and Input.is_action_just_pressed("dialogue_next"):
		if _action_end_paused:
			var action = server.next_action()
			if action != null:
				execute_action(action)
			else:
				visible = false
				_action_end_paused = false
				_current_line = null
				emit_signal("paused")
				emit_signal("ended")
		elif _current_line.nodes.size() == 1 and _current_line.nodes[0] is DialogueServer.TextNode:
			_dialogue_label.percent_visible = 1
			end_line()



func set_speaker(speaker: String, picture: String):
	_speaker_label.text = speaker
	var image = null
	match picture:
		"boss":
			image = load("res://dialogue/phone.png")
		"frankie":
			image = load("res://dialogue/frankie.png")
		_:
			if picture.begins_with("tony_"):
				image = load("res://dialogue/drunk_tony/" + picture.substr(5) + ".png")
			else:
				print("Error: Unknown picture ", picture)
				return
	
	_speaker_picture.texture = image


func play_sequence(id: String):
	server.load_sequence(id)
	execute_action(server.next_action())
	visible = true


func resume():
	visible = true
	execute_action(server.next_action())


func execute_action(action):
	_action_end_paused = false
	if action is DialogueServer.LineAction:
		_dialogue_label.visible_characters = 0
		_dialogue_label.text = action.nodes[0].content
		_current_line = action
		_current_node_index = 0
		_char_in_node_index = 0
		_dialogue_time = 0
	else:
		_current_line = null
		if action is DialogueServer.SpeakerAction:
			set_speaker(action.name, action.picture)
			execute_action(server.next_action())
		elif action is DialogueServer.PauseAction:
			emit_signal("paused")
			visible = false
			_action_end_paused = false
			_current_line = null
			


func advance():
	var node = _current_line.nodes[_current_node_index]
	if node is DialogueServer.TextNode:
		_dialogue_label.visible_characters += 1

	_char_in_node_index += 1
	if _char_in_node_index >= node.length:
		_char_in_node_index = 0
		_current_node_index += 1
		if _current_node_index >= _current_line.nodes.size():
			end_line()


func end_line():
	_action_end_paused = true
	_dialogue_time = -1


func clear():
	visible = false
	_action_end_paused = false
	_current_line = null
	_dialogue_time = -1
