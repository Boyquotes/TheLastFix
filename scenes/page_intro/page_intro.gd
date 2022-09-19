extends GUIScene


var _text_prog = 0
const _text_speed = 0.5

var _page_prog = -1
var _page_speed = 0
const _page_max_speed = 0.8
const _page_friction = 0.04

onready var _label = $Label
onready var _page = $Page


func _process(delta):
	if _text_prog < 1:
		_text_prog += _text_speed * delta
		if _text_prog >= 1:
			_text_prog = 1

		_label.percent_visible = _text_prog
		_page_prog = _text_prog * _text_prog * (3 - 2 * _text_prog) - 1  # Smoothstep
	else:
		var page_dir = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
		if page_dir != 0:
			_page_speed += page_dir * 5 * delta
			if abs(_page_speed) > _page_max_speed:
				_page_speed = sign(_page_speed) * _page_max_speed

		_label.visible = _page_prog < 0.12
		_page_prog += _page_speed * delta
		if _page_prog < 0:
			_page_prog = 0

		_page_speed -= sign(_page_speed) * _page_friction
		if abs(_page_speed) < _page_friction:
			_page_speed = 0

	_page.rect_position.y = 22 - _page_prog * (22 + _page.rect_size.y)
	if _page_prog >= 1:
		Game.unload_gui()
		Game.load_level(load("res://scenes/city/city.tscn"))
