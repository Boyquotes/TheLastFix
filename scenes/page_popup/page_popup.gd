extends GUIScene

signal close_page

var _prog = 0
const _speed = 1

var _dir = 1

onready var _page = $Page


func _process(delta):
	if _dir != 0:
		_prog += _speed * delta * _dir
		if _prog >= 1:
			_prog = 1
			_dir = 0
		elif _prog < 0:
			Game.unload_gui()

		modulate.a = _prog
		if _dir > 0:
			_page.prog = _prog * _prog * (3 - 2 * _prog) - (1 - _page.min_prog)  # Smoothstep
	else:
		_page.enabled = true
		if Input.is_action_just_pressed("interact"):
			emit_signal("close_page")
			_page.enabled = false
			_dir = -2