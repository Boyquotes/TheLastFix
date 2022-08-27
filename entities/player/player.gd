extends KinematicBody2D

class_name Player


export var control_enabled = true

const _gravity = 12
const _friction = 10
const _walk_speed = 100
const _jump_speed = 180
const _pull_speed = 30
const _terminal_velocity = 250
const _ghook_color = Color(0, 149.0/256.0, 1)

var _velocity = Vector2.ZERO
var _looking = Vector2.RIGHT
var _jump_time = -1
var _grapnel: Grapnel
var _pulling = false
var _ghook_length = 0

onready var _animation_player = $AnimationPlayer
onready var _sprite = $Sprite


func _ready():
	play_animation("idle")


func _process(_delta):
	update()


func _draw():
	if _grapnel.active:
		draw_line(Vector2.ZERO, _grapnel.position - position, _ghook_color)


func play_animation(name: String):
	_animation_player.play(name)


func _walking():
	_looking.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	var _walkdir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if not control_enabled:
		_walkdir = 0
		_looking.y = 0

	if _walkdir == 0:
		if is_on_floor() and _animation_player.current_animation == "walk":
			play_animation("idle")
		_looking.x = (-1 if _sprite.flip_h else 1) if _looking.y == 0 else 0
	else:
		if is_on_floor():
			play_animation("walk")
		_sprite.flip_h = _walkdir < 0
		_looking.x = _walkdir

	return lerp((_walk_speed * _walkdir) * (0.25 if is_on_floor() else 0.15), _walkdir * _friction, abs(_velocity.x) / 100) - min(_friction, abs(_velocity.x)) * sign(_velocity.x)


func _jumping():
	if not control_enabled:
		return 0

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			_jump_time = 0
			return Vector2(0, -_jump_speed)
		#elif is_on_wall() and _velocity.x != 0:
		#	_jump_time = 0
		#	return Vector2(-sign(_velocity.x) * _jump_speed, -_jump_speed)

	if Input.is_action_just_released("jump") and _velocity.y < 0 and _jump_time >= 0:
		var pushdown = 0.6 * (_jump_speed - 0.7 * _jump_time * _gravity)
		_jump_time = -1
		return Vector2(0, pushdown)
	
	return Vector2.ZERO


func _falling():
	var gravity_strength = 1.0
	if is_on_floor():
		return 0.01
	if _jump_time >= 0:
		gravity_strength = 0.8
		_jump_time += 1
		
	return _gravity * gravity_strength


func _grappling(_delta):
	if Input.is_action_pressed("grapple") != _grapnel.active:
		if Input.is_action_pressed("grapple"):
			_grapnel.shoot(position, _looking)
		else:
			_grapnel.hide()
			_pulling = false

	if _pulling:
		var dist = _grapnel.position - position
		return dist.normalized() * min(dist.length() / _ghook_length, 1) * _pull_speed
	return Vector2.ZERO


func _physics_process(delta):
	_velocity.x += _walking()
	_velocity.y += _falling()
	_velocity += _jumping() + _grappling(delta)
	
	_velocity = move_and_slide(_velocity, Vector2.UP).limit_length(_terminal_velocity)


func set_grapnel(node: Grapnel):
	_grapnel = node


func _on_Grapnel_hit(hit_pos: Vector2):
	_pulling = true
	_ghook_length = (hit_pos - position).length()
