extends Object

class_name Dialogue

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
	
	func _to_string():
		var result = ""
		for node in nodes:
			result += node._to_string()
		return result


class SpeakerAction:
	var name = ""
	
	func _to_string():
		return "<set speaker to " + name + ">"


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

	parser.read()
	parse_node(parser)
	_current_sequence = null
	_current_line = null


func parse_node(parser: XMLParser):
	if parser.get_node_type() == XMLParser.NODE_TEXT:
		var data = parser.get_node_data()
		if data.strip_edges().empty():
			parser.read()
			parse_node(parser)
			return

		var node = TextNode.new()
		node.content = data
		_current_line.nodes.append(node)
	else:
		match parser.get_node_name():
			'seq':
				_current_sequence = DialogueSequence.new()
				sequences[parser.get_attribute_value(0)] = _current_sequence
			'l':
				_current_line = LineAction.new()
				_current_sequence.actions.append(_current_line)
			'speaker':
				if parser.read() != OK or parser.get_node_type() != XMLParser.NODE_TEXT:
					return

				var speaker = SpeakerAction.new()
				speaker.name = parser.get_node_data()
				_current_sequence.actions.append(speaker)

		while parser.read() == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				parser.read()
				break

			parse_node(parser)


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
