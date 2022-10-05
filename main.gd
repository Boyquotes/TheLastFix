extends Node2D

class_name Main


signal dialogue_paused
signal dialogue_ended


onready var _camera = $Camera
onready var _level_container = $LevelContainer
onready var _level_view = $LevelView
onready var _hud = $HUD
onready var _dialogue_box = $HUD/DialogueBox
onready var _speaker_picture = $HUD/DialogueBox/SpeakerPicture
onready var _speaker_label = $HUD/DialogueBox/SpeakerLabel
onready var _dialogue_label = $HUD/DialogueBox/Dialogue

var _current_level = null
var _current_gui = null


var dialogue = Dialogue.new()

var _current_node_index = 0
var _char_in_node_index = 0
var _current_line = null
var _action_end_paused = false

var _dialogue_time = -1.0
const _dialogue_speed = 0.025


func _ready():
	dialogue.parse()
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
	if _dialogue_time >= 0:
		_dialogue_time += delta
		if _dialogue_time >= _dialogue_speed:
			_dialogue_time = 0
			advance_dialogue()

	if _current_line != null and Input.is_action_just_pressed("dialogue_next"):
		if _action_end_paused:
			var action = dialogue.next_action()
			if action != null:
				execute_action(action)
			else:
				_dialogue_box.visible = false
				_action_end_paused = false
				_current_line = null
				emit_signal("dialogue_paused")
				emit_signal("dialogue_ended")
		elif _current_line.nodes.size() == 1 and _current_line.nodes[0] is Dialogue.TextNode:
			_dialogue_label.percent_visible = 1
			end_dialogue_line()


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


func set_dialogue_speaker(speaker: String, picture: String):
	_speaker_label.text = speaker
	var image = null
	match picture:
		"boss":
			image = load("res://dialogue/phone.png")
		"frankie":
			image = load("res://dialogue/frankie.png")
		_:
			print("Error: Unknown picture ", picture)
			return
	
	_speaker_picture.texture = image


func play_dialogue_sequence(id: String):
	dialogue.load_sequence(id)
	execute_action(dialogue.next_action())
	_dialogue_box.visible = true


func continue_dialogue():
	_dialogue_box.visible = true
	execute_action(dialogue.next_action())


func execute_action(action):
	_action_end_paused = false
	if action is Dialogue.LineAction:
		_dialogue_label.visible_characters = 0
		_dialogue_label.text = action.nodes[0].content
		_current_line = action
		_current_node_index = 0
		_char_in_node_index = 0
		_dialogue_time = 0
	else:
		_current_line = null
		if action is Dialogue.SpeakerAction:
			set_dialogue_speaker(action.name, action.picture)
			execute_action(dialogue.next_action())
		elif action is Dialogue.PauseAction:
			emit_signal("dialogue_paused")
			_dialogue_box.visible = false
			_action_end_paused = false
			_current_line = null
			


func advance_dialogue():
	var node = _current_line.nodes[_current_node_index]
	if node is Dialogue.TextNode:
		_dialogue_label.visible_characters += 1

	_char_in_node_index += 1
	if _char_in_node_index >= node.length:
		_char_in_node_index = 0
		_current_node_index += 1
		if _current_node_index >= _current_line.nodes.size():
			end_dialogue_line()


func end_dialogue_line():
	_action_end_paused = true
	_dialogue_time = -1


func get_player():
	if _current_level is PlayableLevel:
		return _current_level.get_player()
	return null
