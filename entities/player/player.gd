extends KinematicBody2D

class_name Player


export var control_enabled = true

const _gravity = 12
const _friction = 10
const _crawl_speed = 40
const _walk_speed = 100
const _jump_speed = 180
const _pull_speed = 30
const _terminal_velocity = 250
const _grapple_suck_dist = 3.5

var _velocity = Vector2.ZERO
var _looking = Vector2.RIGHT
var _jump_time = -1
var _grapnel = null
var _pulling = false
var _ghook_length = 0
var _crouching = false

onready var _animation_player = $AnimationPlayer
onready var _sprite = $Sprite


func _ready():
	play_animation("idle")


func play_animation(name: String):
	_animation_player.playback_active = true
	_animation_player.play(name)


func _walking():
	var prev_look_vertical = _looking.y
	_looking.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	_crouching = _looking.y > 0
	var _walkdir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if not control_enabled:
		_walkdir = 0
		_looking.y = 0

	var speed = _crawl_speed if _crouching else _walk_speed 
	if _animation_player.current_animation == "crawl":
		_animation_player.playback_active = _walkdir != 0

	if _walkdir == 0:
		if is_on_floor():
			if _animation_player.current_animation == "walk":
				play_animation("idle")
		_looking.x = (-1 if _sprite.flip_h else 1) if _looking.y == 0 else 0
	else:
		if is_on_floor():
			play_animation("crawl" if _crouching else "walk")
		_sprite.flip_h = _walkdir < 0
		_looking.x = _walkdir

	if is_on_floor():
		if _crouching != (prev_look_vertical > 0):
			if _crouching:
				play_animation("crouch")
				_animation_player.queue("crawl")
				return -_velocity.x
			play_animation("get_up")
		if _looking.y < 0 and prev_look_vertical >= 0:
			play_animation("look_up")
		elif _looking.y >= 0 and prev_look_vertical < 0:
			play_animation("idle")

	return lerp((speed * _walkdir) * (0.25 if is_on_floor() else 0.15), _walkdir * _friction, abs(_velocity.x) / 100) - min(_friction, abs(_velocity.x)) * sign(_velocity.x)


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


func _grappling(delta):
	if Input.is_action_pressed("grapple") != _grapnel.active:
		if Input.is_action_pressed("grapple"):
			if not _crouching:
				_grapnel.shoot(position, _looking)
		else:
			_grapnel.hide()
			_pulling = false

	if _pulling:
		var dist = _grapnel.position - position
		if dist.length() < _grapple_suck_dist:
			return dist - _velocity
		return dist.normalized() * _pull_speed
	return Vector2.ZERO


func _physics_process(delta):
	var prev_velocity = _velocity

	_velocity.x += _walking()
	_velocity.y += _falling()
	_velocity += _jumping() + _grappling(delta)
	
	var was_airborne = not is_on_floor()
	
	_velocity = move_and_slide(_velocity, Vector2.UP).limit_length(_terminal_velocity)
	
	if is_on_floor():
		_jump_time = -1
		if was_airborne:
			play_animation("crouch" if _crouching else "land")
	else:
		if _velocity.y < 0:
			play_animation("jump")
		elif _velocity.y > 0:
			_jump_time = -1
			if prev_velocity.y <= 0:
				play_animation("fall")


func set_grapnel(node):
	_grapnel = node


func _on_Grapnel_hit(hit_pos: Vector2):
	_pulling = true
	_ghook_length = (hit_pos - position).length()
