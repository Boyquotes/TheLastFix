extends GUIScene


var _text_prog = 0
const _text_speed = 0.5

@onready var _label = $Label
@onready var _page = $Page


func _process(delta):
	if _text_prog < 1:
		_text_prog += _text_speed * delta
		if _text_prog >= 1:
			_text_prog = 1

		_label.visible_ratio = _text_prog
		_page.prog = _text_prog * _text_prog * (3 - 2 * _text_prog) - (1 - _page.min_prog)  # Smoothstep
	else:
		_page.enabled = true
		_label.visible = _page.prog < 0.12


func _on_Page_reached_max():
	Game.unload_gui()
	Game.load_level(load("res://scenes/city/city_a/city.tscn"))
