extends KinematicBody2D

class_name Grapnel


signal hit(position)

const _speed = 300

var _held_angle = 0
export var angle = 0
var _velocity = Vector2.ZERO
var _origin = null

onready var _sprite = $Sprite
onready var _collision = $Collision
onready var _particles = $Particles

export var active = false
export var hit_angle = 0

var chain_texture = preload("res://entities/player/grapnel/chain.png")
var chain_1 = null
var chain_2 = null


func _ready():
	chain_1 = AtlasTexture.new()
	chain_1.atlas = chain_texture
	chain_1.region = Rect2(0, 0, 3, 3)

	chain_2 = AtlasTexture.new()
	chain_2.atlas = chain_texture
	chain_2.region = Rect2(3, 0, 3, 3)


func hold_angle(value: int):
	_held_angle = value
	if active:
		return

	angle = value

	if value % 90 == 45:
		_sprite.frame = 1
		value -= 45
	else:
		_sprite.frame = 0
	
	rotation_degrees = -value


func shoot(direction: Vector2):
	_velocity = direction
	_sprite.frame = 1 if _velocity.x != 0 and _velocity.y != 0 else 0
	rotation = -_velocity.angle_to(Vector2.RIGHT if _sprite.frame != 1 else Vector2(1, -1))
	_particles.rotation = _velocity.angle() - rotation + PI
	_collision.disabled = false

	active = true
	visible = true


func retract():
	active = false
	_particles.visible = false
	_collision.disabled = true
	hold_angle(_held_angle)
	update()


func _physics_process(delta):
	if not active:
		return

	var collision = move_and_collide(_velocity * _speed * delta)
	if collision != null:
		_particles.visible = true
		_particles.emitting = true
		_particles.restart()
		hit_angle = -round((-collision.normal).angle() * 180 / PI)
		emit_signal("hit", collision.position)
		_collision.disabled = true
		position += _velocity * 2
		_velocity = Vector2.ZERO


func _process(_delta):
	if active:
		update()
	else:
		position = _origin.global_position


func _draw():
	if not active:
		return

	var target = _origin.global_position - position
	if target.length() < 1:
		return
	target += Vector2.LEFT.rotated(-_held_angle / 180.0 * PI)

	draw_set_transform(Vector2(0, 1.5), target.angle() - rotation, Vector2(1, 1))
	var even = false
	for i in range(0, target.length(), 3):
		draw_texture(chain_1 if even else chain_2, Vector2.RIGHT * i)
		even = not even

func set_origin(origin):
	_origin = origin
