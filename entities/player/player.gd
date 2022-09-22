extends KinematicBody2D

class_name Player

signal reached_target


export var control_enabled = true
export var grapnel_enabled = true
export var air_frame = -1 setget _set_air_frame
export var spawnpoint: Vector2

const _gravity = 12
const _friction = 10
const _crawl_speed = 40
const _walk_speed = 100
const _jump_speed = 180
const _walljump_speed = 120
const _terminal_velocity = 250
const _grapple_hold_dist = 5

var _velocity = Vector2.ZERO
var _looking = Vector2.RIGHT
var _jump_time = -1
var _grapnel = null
var _pulling = false
var _holding_wall = false
var _crouching = false
var _was_airborne = false
var _flipped = false

var _target_pos = null
const _autowalk_snap_prox = 1

var _grapnel_origins = {}

onready var _animation_player = $AnimationPlayer
onready var _sprite = $Sprite
onready var _hook_origin = $HookOrigin


func _ready():
	load_grapnel_origins()


func load_grapnel_origins():
	var origins_image = preload("res://entities/player/player_grapnel_origins.png")
	origins_image.lock()
	for x in range(origins_image.get_width() / 18):
		for y in range(origins_image.get_height() / 18):
			var total_pixels = 0
			var total_pos = Vector2.ZERO
			var angle = 0

			for sub_x in range(18):
				for sub_y in range(18):
					var color = origins_image.get_pixel(x * 18 + sub_x, y * 18 + sub_y)
					var found = true
					match color:
						Color.white:
							angle = 0
						Color.red:
							angle = 90
						Color.green:
							angle = 45
						Color.blue:
							angle = -45
						Color.magenta:
							angle = -90
						_:
							found = false
					if found:
						total_pixels += 1
						total_pos += Vector2(sub_x, sub_y)

			if total_pixels > 0:
				var avg_pos = total_pos / total_pixels - Vector2(8.5, 9.5)
				_grapnel_origins[Vector2(x, y)] = Vector3(avg_pos.x, avg_pos.y, angle)
			else:
				_grapnel_origins[Vector2(x, y)] = null

	origins_image.unlock()


func update_air_frame():
	var dir_index = 0
	if _looking.y < 0:
		dir_index = 4 if _looking.x == 0 else 5
	elif _looking.y > 0:
		dir_index = 7 if _looking.x == 0 else 6
	else:
		dir_index = 3

	_sprite.frame_coords = Vector2(air_frame, dir_index)


func _set_air_frame(frame: int):
	air_frame = frame
	if frame >= 0:
		update_air_frame()


func play_animation(name: String):
	_animation_player.playback_active = true
	_animation_player.play(name)


func play_idle():
	air_frame = -1
	if _looking.y == 0:
		play_animation("idle")
	elif _looking.y < 0:
		play_animation("look_up")
		_animation_player.seek(0.1)
	elif _looking.y > 0:
		if _pulling:
			play_animation("idle")
		else:
			play_animation("crouch")


func _walking():
	var prev_looking = _looking
	_looking.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	_crouching = is_on_floor() and _looking.y > 0 and not _grapnel.active
	var _walkdir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var speed = _crawl_speed if _crouching else _walk_speed 
	if _animation_player.current_animation == "crawl":
		_animation_player.playback_active = _walkdir != 0

	if _walkdir == 0:
		if air_frame < 0:
			if _animation_player.current_animation == "walk" or _animation_player.current_animation == "walk_point_up":
				play_idle()
		_looking.x = (-1 if _flipped else 1) if _looking.y == 0 else 0
	else:
		if air_frame < 0 or air_frame > 2:
			air_frame = -1
			if _crouching:
				play_animation("crawl")
			elif _looking.y < 0:
				play_animation("walk_point_up")
			else:
				play_animation("walk")
		_flipped = _walkdir < 0
		_looking.x = _walkdir

	if air_frame < 0:
		if _crouching != (prev_looking.y > 0) and not _grapnel.active:
			if _crouching:
				play_animation("crouch")
				_animation_player.queue("crawl")
				return -_velocity.x
			play_animation("get_up")
		if _looking.y < 0 and prev_looking.y >= 0:
			play_animation("look_up")
		elif _looking.y >= 0 and prev_looking.y < 0:
			play_idle()
	elif _looking != prev_looking:
		update_air_frame()

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
			return Vector2((-_walljump_speed if _flipped else _walljump_speed), -_jump_speed)
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
		return 1
	if _jump_time >= 0:
		gravity_strength = 0.8
		_jump_time += 1
	if _pulling:
		gravity_strength *= 0.6
		
	return _gravity * gravity_strength


func _grappling(_delta):
	if Input.is_action_just_pressed("grapple") or Input.is_action_just_released("grapple"):
		if Input.is_action_pressed("grapple") and grapnel_enabled:
			if not _crouching:
				_grapnel.shoot(_looking)
		elif _grapnel.active:
			_grapnel.retract()
			_pulling = false
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
			_sprite.frame_coords = Vector2(0, 12)
			_flipped = _grapnel.hit_angle == 0
		return pull
	else:
		_holding_wall = false

	return Vector2.ZERO


func _physics_process(delta):
	var prev_velocity = _velocity
	var prev_flipped = _flipped

	if not _holding_wall and control_enabled:
		_velocity.x += _walking()
	_velocity.y += _falling()
	_velocity += _jumping()
	if control_enabled:
		_velocity += _grappling(delta)
	elif _target_pos != null:
		_velocity.x += _autowalk(delta)
	else:
		_looking = Vector2.RIGHT
	
	_velocity = move_and_slide(_velocity, Vector2.UP).limit_length(_terminal_velocity)
	
	if _flipped != prev_flipped:
		scale.x = -1
	
	if _holding_wall:
		return
	
	if _pulling and not (is_on_floor() and _grapnel.hit_angle == -90):
		_animation_player.stop()
		_sprite.frame_coords.y = 11
		var angle = -(_grapnel.position - position).angle() * 180.0 / PI
		if angle > 90.0:
			angle = 180 - angle
		elif angle < -90.0:
			angle += 180

		if angle > 80:
			_sprite.frame_coords.x = 0
		elif angle > 10:
			_sprite.frame_coords.x = 1
		elif angle > -10:
			_sprite.frame_coords.x = 2
		elif angle > -80:
			_sprite.frame_coords.x = 3
		else:
			_sprite.frame_coords.x = 4
	elif is_on_floor():
		_jump_time = -1
		if _was_airborne:
			if _looking.y > 0 and not _grapnel.active:
				air_frame = -1
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

	_was_airborne = not is_on_floor()


func set_grapnel(node):
	_grapnel = node
	_grapnel.set_origin(_hook_origin)
	_grapnel.set_player(self)


func _on_Grapnel_hit():
	_pulling = true


func _on_Grapnel_retract():
	_pulling = false


func get_velocity():
	return _velocity


func _on_Sprite_frame_changed():
	var _origin_pos = _grapnel_origins[_sprite.frame_coords]
	if _origin_pos == null:
		_grapnel.visible = false
	else:
		_grapnel.visible = visible
		_hook_origin.position = Vector2(_origin_pos.x, _origin_pos.y)
		var angle = _origin_pos.z
		if _flipped and int(angle) % 180 != 90:
			angle = 180 - angle
		_grapnel.hold_angle(angle)


func go_to(position: Vector2):
	_target_pos = position
	_looking = Vector2.ZERO


func _autowalk(delta):
	var _walkdir = 0
	if abs(position.x - _target_pos.x) < _autowalk_snap_prox:
		_flipped = false
		if _animation_player.current_animation == "walk":
			play_idle()
		
		var velocity = (_target_pos.x - position.x) / delta - _velocity.x
		if is_on_floor() and velocity + _velocity.x == 0:
			emit_signal("reached_target")
			_target_pos = null

		return velocity

	if air_frame < 0:
		play_animation("walk")

	if position.x < _target_pos.x:
		_walkdir = 1
		_flipped = false
	elif position.x > _target_pos.x:
		_walkdir = -1
		_flipped = true
	
	return lerp((_walk_speed * _walkdir) * (0.25 if is_on_floor() else 0.15), _walkdir * _friction, abs(_velocity.x) / 100) - min(_friction, abs(_velocity.x)) * sign(_velocity.x)


func _on_Player_visibility_changed():
	_grapnel.visible = visible


func die():
	global_position = spawnpoint
	play_idle()
	_grapnel.retract()
