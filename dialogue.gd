extends Control

class_name Dialogue

signal paused
signal ended

var _current_node_index = 0
var _char_in_node_index = 0
var _current_line: DialogueServer.LineAction
var _action_end_paused = false

var _dialogue_time = 0.0

var dialogue_speed = 0.025
var pitch_variation = 0.25
var chars_per_sound = 2

const punctuation_lengths = {
	',': 0.2,
	'.': 0.4,
	'?': 0.4
}

var server = DialogueServer.new()

onready var _speaker_picture = $SpeakerPicture
onready var _speaker_label = $SpeakerLabel
onready var _speaker_sound = $SpeakerSound
onready var _dialogue_label = $Dialogue


func _ready():
	server.parse()


func set_sound(sound: Resource, pitch_var: float = 0.25, chars_per: int = 2, speed: float = 0.025):
	_speaker_sound.stream = sound
	dialogue_speed = speed
	pitch_variation = pitch_var
	chars_per_sound = chars_per


func _process(delta):
	if _dialogue_time > 0:
		_dialogue_time -= delta
		if _dialogue_time <= 0:
			_dialogue_time = dialogue_speed
			advance()

	if _current_line != null and Input.is_action_just_pressed("dialogue_next"):
		if _action_end_paused:
			var action = server.next_action()
			if action != null:
				if not (action is DialogueServer.LineAction):
					_current_line = null
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
			set_sound(load("res://dialogue/sound/boss.mp3"))
		"frankie":
			image = load("res://dialogue/frankie.png")
			set_sound(load("res://dialogue/sound/frankie.mp3"), 0.125, 3)
		_:
			if picture.begins_with("tony_"):
				image = load("res://dialogue/drunk_tony/" + picture.substr(5) + ".png")
				if picture == "tony_muy_tired":
					set_sound(load("res://dialogue/sound/tony_1.mp3"), 0.08, 3, 0.04)
				elif picture == "tony_wistful":
					set_sound(load("res://dialogue/sound/tony_2.mp3"), 0.125, 3, 0.04)
				elif picture == "tony_annoyed":
					set_sound(load("res://dialogue/sound/tony_3.mp3"), 0.125, 3, 0.035)
				elif picture == "tony_angry":
					set_sound(load("res://dialogue/sound/tony_4.mp3"), 0.08, 3, 0.035)
			else:
				print("Error: Unknown picture ", picture)
				return
	
	_speaker_picture.texture = image


func play_sequence(id: String):
	server.load_sequence(id)
	execute_action(server.next_action())
	visible = true


func resume():
	if _current_line != null:
		_dialogue_time = dialogue_speed
	else:
		visible = true
		execute_action(server.next_action())


func execute_action(action):
	_action_end_paused = false
	if action is DialogueServer.LineAction:
		_dialogue_label.visible_characters = 0
		_dialogue_label.text = ""
		for node in action.nodes:
			if node is DialogueServer.TextNode:
				_dialogue_label.text += node.content
		_current_line = action
		_current_node_index = 0
		_char_in_node_index = 0
		_dialogue_time = dialogue_speed
	else:
		if action is DialogueServer.SpeakerAction:
			set_speaker(action.name, action.picture)
			execute_action(server.next_action())
		elif action is DialogueServer.PauseAction:
			emit_signal("paused")
			if _current_line == null:
				visible = false
			_action_end_paused = false
			_dialogue_time = 0.0


func advance():
	var node = _current_line.nodes[_current_node_index]
	if node is DialogueServer.TextNode:
		_dialogue_label.visible_characters += 1

		var ch = node.content[_char_in_node_index]
		_speaker_sound.pitch_scale = 1 + (randf() - 0.5) * pitch_variation * 2
		if _current_line.wait_on_punctuation and ch in punctuation_lengths:
			_dialogue_time = punctuation_lengths[ch]
			_speaker_sound.play()
			
		elif _dialogue_label.visible_characters % chars_per_sound == 1:
			_speaker_sound.play()

		_char_in_node_index += 1
		if _char_in_node_index >= node.length:
			_char_in_node_index = 0
			_current_node_index += 1
	else:
		execute_action(node)
		_current_node_index += 1

	if _current_node_index >= _current_line.nodes.size():
		end_line()

func end_line():
	_action_end_paused = true
	_dialogue_time = 0.0


func clear():
	visible = false
	_action_end_paused = false
	_current_line = null
	_dialogue_time = 0.0
