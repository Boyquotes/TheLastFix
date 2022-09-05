extends Object

class_name Dialogue

class TextNode:
	var content = ""
	
	func _to_string():
		return '"' + content + '"'


class DialogueSequence:
	var lines = Array()
	
	func _to_string():
		var result = ""
		for line in lines:
			for node in line:
				result += node._to_string() 
			result += '\n'

		return result


var _current_sequence: DialogueSequence
var _current_line: Array

var sequences = Dictionary()


func parse():
	var parser = XMLParser.new()
	var error = parser.open("res://dialogue/dialogue.xml")
	if error:
		print("Error opening dialogue file: ", error)

	parser.read()
	parse_node(parser)
	print(sequences)


func parse_node(parser: XMLParser):
	if parser.get_node_type() == XMLParser.NODE_TEXT:
		var node = TextNode.new()
		node.content = parser.get_node_data()
		_current_line.append(node)
	else:
		match parser.get_node_name():
			'seq':
				_current_sequence = DialogueSequence.new()
				sequences[parser.get_attribute_value(0)] = _current_sequence
			'l':
				_current_line = Array()
				_current_sequence.lines.append(_current_line)
		while parser.read() == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				parser.read()
				break

			parse_node(parser)

