extends KinematicBody2D

class_name Player


export var control_enabled = true

const _gravity = 12
const _friction = 10
const _crawl_speed = 40
const _walk_speed = 100
const _jump_speed = 180
const _terminal_velocity = 250
const _grapple_hold_dist = 5

var _velocity = Vector2.ZERO
var _looking = Vector2.RIGHT
var _jump_time = -1
var _grapnel = null
var _pulling = false
var _holding_wall = false
var _ghook_length = 0
var _crouching = false

var _flipped = false

onready var _animation_player = $AnimationPlayer
onready var _sprite = $Sprite
onready var _hook_origin = $HookOrigin


func _ready():
	play_animation("idle")


func play_animation(name: String, show_hook = true, hook_angle = 0):
	_animation_player.playback_active = true
	_animation_player.play(name)
	if _grapnel != null:
		set_grapnel_angle(hook_angle, show_hook)


func play_idle():
	if _looking.y == 0:
		play_animation("idle")
	elif _looking.y < 0:
		play_animation("look_up")
	elif _looking.y > 0:
		if _pulling:
			play_animation("idle")
		else:
			play_animation("crouch")


func set_grapnel_angle(angle: int, visible: bool = true):
	if _flipped and angle % 180 != 90:
		angle = 180 - angle
	_grapnel.hold_angle(angle)
	_grapnel.visible = visible


func _walking():
	var prev_look_vertical = _looking.y
	_looking.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	_crouching = is_on_floor() and _looking.y > 0 and not _grapnel.active
	var _walkdir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if not control_enabled:
		_walkdir = 0
		_looking.y = 0

	var speed = _crawl_speed if _crouching else _walk_speed 
	if _animation_player.current_animation == "crawl":
		_animation_player.playback_active = _walkdir != 0

	if _walkdir == 0:
		if is_on_floor():
			if _animation_player.current_animation == "walk" or _animation_player.current_animation == "walk_point_up":
				play_idle()
		_looking.x = (-1 if _flipped else 1) if _looking.y == 0 else 0
	else:
		if is_on_floor():
			if _crouching:
				play_animation("crawl", false)
			elif _looking.y < 0:
				play_animation("walk_point_up", true, 45)
			else:
				play_animation("walk")
		_flipped = _walkdir < 0
		_looking.x = _walkdir

	if is_on_floor():
		if _crouching != (prev_look_vertical > 0) and not _grapnel.active:
			if _crouching:
				play_animation("crouch")
				_animation_player.queue("crawl")
				return -_velocity.x
			play_animation("get_up")
		if _looking.y < 0 and prev_look_vertical >= 0:
			play_animation("look_up")
		elif _looking.y >= 0 and prev_look_vertical < 0:
			play_idle()

	return lerp((speed * _walkdir) * (0.25 if is_on_floor() else 0.15), _walkdir * _friction, abs(_velocity.x) / 100) - min(_friction, abs(_velocity.x)) * sign(_velocity.x)


func _jumping():
	if not control_enabled or _crouching:
		return Vector2.ZERO

	if Input.is_action_just_pressed("jump"):
		if _holding_wall:
			_jump_time = 0
			_holding_wall = false
			_grapnel.retract()
			_pulling = false
			return Vector2((-_jump_speed if _flipped else _jump_speed), -_jump_speed)
		if is_on_floor():
			_jump_time = 0
			return Vector2(0, -_jump_speed)

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
	if _pulling:
		gravity_strength *= 0.6
		
	return _gravity * gravity_strength


func _grappling(_delta):
	if Input.is_action_just_pressed("grapple") or Input.is_action_just_released("grapple"):
		if Input.is_action_pressed("grapple"):
			if not _crouching:
				_grapnel.shoot(_looking)
		else:
			_grapnel.retract()
			_pulling = false
			if is_on_floor():
				play_idle()

	if _pulling:
		var pull = _grapnel.get_pull(position, _velocity)
		if (
			_grapnel.position.distance_to(position) < _grapple_hold_dist
			and
			not _holding_wall and (_grapnel.hit_angle == 0 or _grapnel.hit_angle == 180)
			):
			_animation_player.stop()
			_holding_wall = true
			_sprite.frame_coords = Vector2(0, 7)
			_flipped = _grapnel.hit_angle == 0
		return pull
	else:
		_holding_wall = false
	return Vector2.ZERO


func _physics_process(delta):
	var prev_velocity = _velocity
	var prev_flipped = _flipped

	if not _holding_wall:
		_velocity.x += _walking()
	_velocity.y += _falling()
	_velocity += _jumping()
	_velocity += _grappling(delta)
	
	var was_airborne = not is_on_floor()
	
	_velocity = move_and_slide(_velocity, Vector2.UP).limit_length(_terminal_velocity)
	
	if _flipped != prev_flipped:
		scale.x = -1
	
	if _holding_wall:
		return
	
	if _pulling and not (is_on_floor() and _grapnel.hit_angle == -90):
		_animation_player.stop()
		_sprite.frame_coords.y = 6
		var angle = -(_grapnel.position - position).angle() * 180.0 / PI
		if angle > 90.0:
			angle = 180 - angle
		elif angle < -90.0:
			angle += 180

		if angle > 80:
			_sprite.frame_coords.x = 0
			_hook_origin.position = Vector2(2.5, -9)
			set_grapnel_angle(90)
		elif angle > 10:
			_sprite.frame_coords.x = 1
			_hook_origin.position = Vector2(6, -6)
			set_grapnel_angle(45)
		elif angle > -10:
			_sprite.frame_coords.x = 2
			_hook_origin.position = Vector2(7, -2.5)
			set_grapnel_angle(0)
		elif angle > -80:
			_sprite.frame_coords.x = 3
			_hook_origin.position = Vector2(7, 3)
			set_grapnel_angle(-45)
		else:
			_sprite.frame_coords.x = 4
			_hook_origin.position = Vector2(4.5, 7)
			set_grapnel_angle(-90)
	elif is_on_floor():
		_jump_time = -1
		if was_airborne:
			if _looking.y > 0 and not _grapnel.active:
				play_animation("crouch")
				_velocity.x = 0
			else:
				play_animation("land")
	else:
		if _velocity.y < 0:
			play_animation("jump")
		elif _velocity.y > 0:
			_jump_time = -1
			if prev_velocity.y <= 0:
				play_animation("fall")

	var space_state = get_world_2d().direct_space_state
	if space_state.intersect_point(_hook_origin.global_position, 1, [self], 2).empty():
		_grapnel.set_origin(_hook_origin)
	else:
		_grapnel.set_origin(self)


func set_grapnel(node):
	_grapnel = node
	_grapnel.set_origin(_hook_origin)


func _on_Grapnel_hit(hit_pos: Vector2):
	_pulling = true
	_ghook_length = (hit_pos - position).length()
