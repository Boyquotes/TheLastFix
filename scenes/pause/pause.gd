extends GUIScene


var prog = 0
var dir = 1

var _fade_speed = 10

var _buttons = []
var _select_index = 0

onready var _arrow = $Arrow


func _ready():
	get_tree().paused = true
	modulate = Color(1, 1, 1, 0)
	_buttons = $Menu/Buttons.get_children()
	$ArrowAnimation.play("point")


func _process(delta):
	if prog < 1 and dir > 0:
		prog += delta * _fade_speed
		if prog >= 1:
			prog = 1
			dir = 0
	elif prog > 0 and dir < 0:
		prog -= delta * _fade_speed
		if prog <= 0:
			prog = 0
			get_tree().paused = false
			Game.unload_gui()

	modulate = Color(1, 1, 1, prog)
	
	if Input.is_action_just_pressed("escape"):
		dir = -1

	if dir >= 0:
		var _select_dir = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
		_select_index = int(max(min(_select_index + _select_dir, _buttons.size() - 1), 0))
		var _button = _buttons[_select_index]
		_arrow.position = (_button.rect_global_position + Vector2(_button.rect_size.x + 7, _button.rect_size.y / 2 + 1)).round()
		
		if Input.is_action_just_pressed("interact"):
			match _select_index:
				0:
					dir = -1
				1:
					pass
