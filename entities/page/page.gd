extends Sprite

signal reached_min
signal reached_max


export var prog = 0 setget _set_prog
export var min_prog = 0.0
export var max_prog = 1.0
export var enabled = true

var _speed = 0
const _max_speed = 0.8
const _friction = 0.04
const height = 196


func _set_prog(_prog):
	prog = _prog
	position.y = -prog * height


func _process(delta):
	if not enabled:
		return

	var dir = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	if dir != 0:
		_speed += dir * 5 * delta
		if abs(_speed) > _max_speed:
			_speed = sign(_speed) * _max_speed

	prog += _speed * delta
	if prog < min_prog:
		prog = min_prog
		emit_signal("reached_min")
	elif prog > max_prog:
		prog = max_prog
		emit_signal("reached_max")

	_speed -= sign(_speed) * _friction
	if abs(_speed) < _friction:
		_speed = 0

	_set_prog(prog)
