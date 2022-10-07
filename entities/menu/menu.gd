extends Control

signal option_pressed(index)


export var enabled = true
export var right_side = false

onready var _arrow = $Arrow
onready var _arrow_animation = $ArrowAnimation

var _buttons = []
var _select_index = 0


func _ready():
	_arrow_animation.play("point")
	_arrow.flip_h = right_side
	for child in get_children():
		if child != _arrow and child != _arrow_animation:
			_buttons.append(child)


func _process(_delta):
	if not enabled:
		return

	var _select_dir = 0
	if Input.is_action_just_pressed("look_down"):
		_select_dir += 1
	if Input.is_action_just_pressed("look_up"):
		_select_dir -= 1
	_select_index = int(max(min(_select_index + _select_dir, _buttons.size() - 1), 0))
	var _button = _buttons[_select_index]
	_arrow.global_position = (
		_button.rect_global_position + Vector2(
			_button.rect_size.x + 7 if right_side else -7,
			_button.rect_size.y / 2 + 1
		)
	).round()
	
	if Input.is_action_just_pressed("interact"):
		emit_signal("option_pressed", _select_index)
