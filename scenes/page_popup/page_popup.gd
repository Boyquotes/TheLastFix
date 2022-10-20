extends GUIScene

signal close_page

var _prog = 0
const _speed = 1

var _dir = 1

onready var _page = $Page

var already_crossed = 0


func set_crossed(count: int):
	already_crossed = count
	_page.set_crossed(count)


func _ready():
	get_tree().paused = true


func _process(delta):
	if _dir != 0:
		_prog += _speed * delta * _dir
		if _prog >= 1:
			_prog = 1
			_dir = 0
			_page.cross_out(already_crossed + 1)
		elif _prog < 0:
			Game.unload_gui()

		modulate.a = _prog
		if _dir > 0:
			_page.prog = _prog * _prog * (3 - 2 * _prog) - (1 - _page.min_prog)  # Smoothstep
	elif _page.enabled:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("escape"):
			get_tree().paused = false
			emit_signal("close_page")
			_page.enabled = false
			_dir = -2


func _on_Page_finished_crossing():
	_page.enabled = true
