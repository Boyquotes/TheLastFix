extends Object

class_name DialogueServer


var _last_speaker_name = ""

class TextNode:
	var content = "" setget _set_content
	var length = 0
	
	func _set_content(text: String):
		content = text
		length = text.length()
	
	func _to_string():
		return '"' + content + '"'


class LineAction:
	var nodes = Array()
	var wait_on_punctuation = true
	
	func _to_string():
		var result = ""
		for node in nodes:
			result += node._to_string()
		return result


class SpeakerAction:
	var name = ""
	var picture = ""

	func _to_string():
		return "<set speaker to " + name + " with pic " + picture + ">"


class PauseAction:
	func _to_string():
		return "<pause>"


class DialogueSequence:
	var actions = Array()
	
	func _to_string():
		var result = ""
		for action in actions:
			result += action._to_string() + '\n'

		return result


var _current_sequence: DialogueSequence
var _current_line: LineAction

var _current_action_index = 0

var sequences = Dictionary()



func parse():
	var parser = XMLParser.new()
	var error = parser.open("res://dialogue/dialogue.xml")
	if error:
		print("Error opening dialogue file: ", error)

	while parser.read() == OK:
		parse_node(parser)

	_current_sequence = null
	_current_line = null


func parse_node(parser: XMLParser):
	if parser.get_node_type() == XMLParser.NODE_TEXT:
		var data = parser.get_node_data()
		if data.strip_edges().empty() and parser.read() == OK:
			parse_node(parser)
			return

		var node = TextNode.new()
		node.content = data
		_current_line.nodes.append(node)
	else:
		var target_array = null
		if _current_line != null:
			target_array = _current_line.nodes
		elif _current_sequence != null:
			target_array = _current_sequence.actions

		var node_name = parser.get_node_name()
		match node_name:
			'seq':
				_current_sequence = DialogueSequence.new()
				var id = ""
				for i in parser.get_attribute_count():
					if parser.get_attribute_name(i) == "id":
						id = parser.get_attribute_value(i)

				sequences[id] = _current_sequence
			'l':
				_current_line = LineAction.new()
				_current_sequence.actions.append(_current_line)
				for i in parser.get_attribute_count():
					if parser.get_attribute_name(i) == "punct":
						_current_line.wait_on_punctuation = (parser.get_attribute_value(i) == "true")
			'speaker':
				if parser.read() != OK or parser.get_node_type() != XMLParser.NODE_TEXT:
					return

				var speaker = SpeakerAction.new()
				speaker.name = parser.get_node_data()
				_last_speaker_name = speaker.name
				speaker.picture = speaker.name.to_lower()
				for i in parser.get_attribute_count():
					if parser.get_attribute_name(i) == "pic":
						speaker.picture = parser.get_attribute_value(i)

				target_array.append(speaker)
			'face':
				var speaker = SpeakerAction.new()
				speaker.name = _last_speaker_name
				for i in parser.get_attribute_count():
					if parser.get_attribute_name(i) == "pic":
						speaker.picture = parser.get_attribute_value(i)
				
				target_array.append(speaker)
			'pause':
				target_array.append(PauseAction.new())

		while parser.read() == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				break
			
			parse_node(parser)

		if node_name == 'l':
			_current_line = null

func load_sequence(id: String):
	if not sequences.has(id):
		print("ERROR: No sequence has the id ", id)
		return

	_current_sequence = sequences[id]
	_current_action_index = -1


func next_action():
	_current_action_index += 1
	if _current_action_index >= _current_sequence.actions.size():
		_current_sequence = null
		_current_action_index = 0
		return null

	return _current_sequence.actions[_current_action_index]
