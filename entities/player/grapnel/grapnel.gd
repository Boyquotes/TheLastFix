extends KinematicBody2D

class_name Grapnel


signal hit(position)

const _speed = 300

var _dir = Vector2.ZERO
var _player = null

onready var _sprite = $Collision/Sprite
onready var _collision = $Collision
onready var _particles = $Particles

export var active = false

var chain_texture = preload("res://entities/player/grapnel/chain.png")


func shoot(origin: Vector2, direction: Vector2):
	position = origin
	visible = true
	active = true
	_dir = direction
	_sprite.frame = 0 if _dir.x != 0 and _dir.y != 0 else 2
	_collision.rotation = -_dir.angle_to(Vector2.UP if _sprite.frame != 0 else Vector2(1, -1))
	_particles.rotation = _dir.angle() + PI
	_collision.disabled = false


func hide():
	active = false
	visible = false
	_particles.visible = false
	_collision.disabled = true


func _physics_process(delta):
	if not active:
		return

	var collision = move_and_collide(_dir * _speed * delta)
	if collision != null:
		_sprite.frame += 1
		_particles.visible = true
		_particles.emitting = true
		_particles.restart()
		emit_signal("hit", collision.position)
		_collision.disabled = true
		position += _dir * 2
		_dir = Vector2.ZERO


func _process(_delta):
	if active:
		update()


func _draw():
	if not active:
		return

	var target = _player.position - position
	draw_set_transform(target.normalized().tangent(), target.angle(), Vector2(1, 1))
	for i in range(0, target.length(), 6):
		draw_texture(chain_texture, Vector2.RIGHT * i)

func set_player(player):
	_player = player
