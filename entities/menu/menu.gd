extends Control

signal option_pressed(index)


@export var enabled = true
@export var right_side = false

@onready var _arrow = $Arrow
@onready var _arrow_animation = $ArrowAnimation
@onready var _select_sound = $SelectSound
@onready var _enter_sound = $EnterSound

var _buttons = []
var _select_index = -1


func _ready():
	_arrow_animation.play("point")
	_arrow.flip_h = right_side
	call_deferred("collect_children")


func collect_children():
	var i = 0
	for child in get_children():
		if child.owner != self:
			if child.visible and _select_index < 0:
				_select_index = i
			i += 1
			_buttons.append(child)


func _process(_delta):
	if not enabled:
		return

	var _select_dir = 0
	if Input.is_action_just_pressed("look_down"):
		_select_dir += 1
	if Input.is_action_just_pressed("look_up"):
		_select_dir -= 1

	var origin_index = _select_index
	if _select_dir != 0:
		while true:
			_select_index += _select_dir
			if _select_index < 0:
				_select_index = 0
			elif _select_index >= _buttons.size():
				_select_index = _buttons.size() - 1
			elif not _buttons[_select_index].visible:
				continue

			break

		if not _buttons[_select_index].visible:
			_select_index = origin_index
	
	var _button = _buttons[_select_index]
	_arrow.global_position = (
		_button.global_position + Vector2(
			_button.size.x + 8 if right_side else -8,
			_button.size.y / 2 + 1
		)
	).round()
	
	if origin_index != _select_index:
		_select_sound.play()
	
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("enter"):
		_enter_sound.play()
		emit_signal("option_pressed", _select_index)
