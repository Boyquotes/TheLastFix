extends KinematicBody2D

class_name Grapnel


signal hit(position)

const _speed = 300

var _dir = Vector2.ZERO

onready var _sprite = $Sprite

export var active = false


func shoot(origin: Vector2, direction: Vector2):
	position = origin
	visible = true
	active = true
	_dir = direction

func hide():
	active = false
	visible = false


func _physics_process(delta):
	if not active:
		return

	var collision = move_and_collide(_dir * _speed * delta)
	if collision != null:
		emit_signal("hit", collision.position)
		_dir = Vector2.ZERO
