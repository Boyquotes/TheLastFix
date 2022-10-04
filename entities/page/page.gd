extends Node2D

signal reached_min
signal reached_max
signal finished_crossing


export var prog = 0.0 setget _set_prog
export var min_prog = 0.0
export var max_prog = 1.0
export var enabled = true setget _set_enabled

var _speed = 0
const _max_speed = 0.8
const _friction = 0.04
const height = 196

var _items = []

onready var _page = $Page
onready var _animation_player = $AnimationPlayer
onready var _up_arrow = $UpArrow
onready var _down_arrow = $DownArrow


func _ready():
	for i in range(1, 11):
		if not _page.has_node(str(i)):
			break
		_items.append(_page.get_node(str(i)))


func set_crossed(count: int):
	for i in count:
		_items[i].frame = _items[i].vframes - 1


func cross_out(index: int):
	_animation_player.play(str(index))


func _set_enabled(value: bool):
	enabled = value
	if value:
		_animation_player.play("arrows")


func _set_prog(_prog):
	prog = _prog
	_page.position.y = -prog * height


func _process(delta):
	if not enabled:
		return

	var dir = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
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

	_up_arrow.visible = prog > min_prog
	_down_arrow.visible = prog < max_prog

	_speed -= sign(_speed) * _friction
	if abs(_speed) < _friction:
		_speed = 0

	_set_prog(prog)


func _on_AnimationPlayer_animation_finished(_anim_name):
	emit_signal("finished_crossing")
