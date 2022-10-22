extends KinematicBody2D

class_name Player

signal reached_target


export var player_visible = true setget _set_player_visible
export var frozen = false
export var control_enabled = true
export var grapnel_enabled = true
export var air_frame = -1 setget _set_air_frame
export var spawnpoint: Vector2
export var snap_to_floor = false
export var inching = false

const _gravity = 12
const _friction = 10
const _crawl_speed = 20
const _walk_speed = 100
const _jump_speed = 180
const _walljump_speed = 120
const _max_velocity = 200
const _terminal_velocity = 200
const _grapple_hold_dist = 5
const _max_coyote_time = 0.1
const _feet_offset = 7
const _autowalk_snap_prox = 1

var _prev_velocity = Vector2.ZERO
var _velocity = Vector2.ZERO
var _looking = Vector2.RIGHT
var _jump_time = -1
var _coyote_time = 0.0
var _grapnel = null
var _pulling = false
var _holding_wall = false
var _crouching = false
var _was_airborne = false
var _flipped = false
var _stuck_crouching = false

var _target_pos = null
var _target_flipped = false

var _collision_extents = PoolVector2Array()

var _grapnel_origins = {}

onready var _animation_player = $AnimationPlayer
onready var _sprite = $Sprite
onready var _collision = $Collision
onready var _hook_origin = $HookOrigin
onready var _light = $PlayerLight
onready var _death_particles = $DeathParticles
onready var _spawn_particles = $SpawnParticles
onready var _land_sound = $Sound/Land
onready var _death_sound = $Sound/Death


func _ready():
	load_grapnel_origins()
	var width = _collision.shape.extents.x
	var height = _collision.shape.extents.y
	_collision_extents.append(_collision.position + Vector2(width, height))
	_collision_extents.append(_collision.position + Vector2(width, -height))
	_collision_extents.append(_collision.position + Vector2(-width, -height))
	_collision_extents.append(_collision.position + Vector2(-width, height))


func load_grapnel_origins():
	var origins_image = preload("res://entities/player/player_grapnel_origins.png")
	origins_image.lock()
	for x in origins_image.get_width() / 18:
		for y in origins_image.get_height() / 18:
			var total_pixels = 0
			var total_pos = Vector2.ZERO
			var angle = 0

			for sub_x in 18:
				for sub_y in 18:
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
							angle = 315
						Color.magenta:
							angle = 270
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
	if name != "crouch" and name != "crawl" and name != "get_up":
		_light.position.y = 0


func play_idle(reset_air_frame = true):
	if reset_air_frame or is_on_floor():
		air_frame = -1
	elif air_frame >= 0:
		update_air_frame()
		return

	if is_on_floor() or _velocity.y == 0:
		if _looking.y == 0:
			play_animation("idle")
		elif _looking.y < 0:
			play_animation("look_up")
			_animation_player.seek(0.1)
		elif _looking.y > 0:
			if _grapnel.active:
				play_animation("idle")
			else:
				play_animation("crouch")
	else:
		if _velocity.y > 0:
			play_animation("fall")
		else:
			play_animation("jump")


func play_walking():
	var prev_anim = _animation_player.current_animation
	var new_anim = "walk_point_up" if _looking.y < 0 else "walk"
	if prev_anim == ("walk" if _looking.y < 0 else "walk_point_up"):
		var time = _animation_player.current_animation_position
		play_animation(new_anim)
		_animation_player.seek(time, true)
	else:
		play_animation(new_anim)


func _walking():
	if inching:
		_looking.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		if _looking.x != 0:
			play_animation("inch_forward" if _looking.x < 0 else "inch_backward")
		if test_move(transform, Vector2(_looking.x, 0)):
			_animation_player.stop(false)
			_sprite.frame_coords = Vector2(0, 15)
		else:
			_animation_player.playback_active = _looking.x != 0
		return 0
	
	var prev_looking = _looking
	_looking.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	if _crouching and test_move(transform, Vector2(0, -9)):  # Make sure the player doesn't uncrouch if he can't
		_stuck_crouching = true
		_crouching = true
		_looking.y = 1
	else:
		if _stuck_crouching and not is_on_floor():
			play_animation("fall")
			_set_air_frame(1)
		_stuck_crouching = false
		_crouching = is_on_floor() and _looking.y > 0 and not _grapnel.active
	
	var _walkdir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
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
			else:
				play_walking()

		_flipped = _walkdir < 0
		_looking.x = _walkdir

	if air_frame < 0:
		if _crouching != (prev_looking.y > 0) and not _grapnel.active:
			if _crouching:
				play_animation("crouch")
				_animation_player.queue("crawl")
				return -_velocity.x
			play_animation("get_up")

		if _walkdir == 0:
			if _looking.y < 0 and prev_looking.y >= 0:
				play_animation("look_up")
			elif _looking.y >= 0 and prev_looking.y < 0:
				play_idle()
	elif _looking != prev_looking:
		update_air_frame()

	if _crouching:
		return _crawl_speed * _walkdir - _velocity.x
	return lerp(_walk_speed * _walkdir * (0.25 if is_on_floor() else 0.15), _walkdir * _friction, abs(_velocity.x) / 100) - min(_friction, abs(_velocity.x)) * sign(_velocity.x)


func _jumping():
	if not control_enabled or _crouching:
		return Vector2.ZERO

	if Input.is_action_just_pressed("jump"):
		if _holding_wall:
			_jump_time = 0
			_holding_wall = false
			_grapnel.retract_immediately()
			_pulling = false
			return Vector2((-_walljump_speed if _flipped else _walljump_speed), -_jump_speed)
		if _coyote_time < _max_coyote_time:
			_jump_time = 0
			_coyote_time = _max_coyote_time
			return Vector2(0, -_jump_speed - _velocity.y)

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

	if _gravity * gravity_strength + _velocity.y > _terminal_velocity:
		return _terminal_velocity - _velocity.y
	return _gravity * gravity_strength


func _grappling(_delta):
	if Input.is_action_just_pressed("grapple") and grapnel_enabled:
		if not _crouching:
			_grapnel.shoot(_looking)
	elif not Input.is_action_pressed("grapple") and _grapnel.active and not _grapnel._retracting:
			_grapnel.retract()
			_pulling = false

	if _pulling:
		var pull = _grapnel.get_pull(position, _velocity)
		
		if _holding_wall:
			return pull

		if (
			_grapnel.position.distance_to(position) < _grapple_hold_dist
			and (_grapnel.hit_angle == 0 or _grapnel.hit_angle == 180)
			):
			_animation_player.stop()
			_holding_wall = true
			_sprite.frame_coords = Vector2(0, 12)
			_flipped = _grapnel.hit_angle == 0
			return pull
		
		# Prevent the player getting stuck on ledges
		var angle = int(-pull.normalized().angle() * 180 / PI)
		if angle < 0:
			angle += 360
		
		angle = int(round(angle / 90.0))
		var space_state = get_world_2d().direct_space_state
		var offset = Vector2.RIGHT.rotated(-angle * PI / 2)
		var intersect_1 = space_state.intersect_point(_collision_extents[angle % 4] + offset + position, 1, [self], 2)
		var intersect_2 = space_state.intersect_point(_collision_extents[(angle + 1) % 4] + offset + position, 1, [self], 2)
		if intersect_1.empty() != intersect_2.empty():
			pull += offset.rotated(PI / 2 * (-1 if intersect_2.empty() else 1)) * 15
		
		return pull
	else:
		_holding_wall = false

	return Vector2.ZERO


func _physics_process(delta):
	if frozen:
		return

	_prev_velocity = _velocity
	var prev_flipped = _flipped

	if not _holding_wall and control_enabled:
		_velocity.x += _walking()

	_velocity.y += _falling()
	if not inching:
		_velocity += _jumping()

	if control_enabled:
		_velocity += _grappling(delta)
	elif _target_pos != null:
		_velocity.x += _autowalk(delta)
	else:
		_looking = Vector2.RIGHT
	
	if snap_to_floor:
		_velocity = move_and_slide_with_snap(
			_velocity,
			Vector2.DOWN * 4 if not _pulling and _jump_time < 0 else Vector2.ZERO,
			Vector2.UP,
			true).limit_length(_max_velocity)
	else:
		_velocity = move_and_slide(_velocity, Vector2.UP, true).limit_length(_max_velocity)

	if is_on_floor():
		_coyote_time = 0.0
	elif _coyote_time < _max_coyote_time:
		_coyote_time += delta
	
	if _flipped != prev_flipped:
		scale.x = -1

	_collision.shape.extents.y = 3.0 if _crouching else 7.5
	_collision.position.y = 4.0 if _crouching else -0.5
	
	if _holding_wall:
		_was_airborne = not is_on_floor()
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
		if _was_airborne and not _crouching:
			_land_sound.volume_db = (_prev_velocity.y / _terminal_velocity - 1.2) * 40
			_land_sound.play()
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
			if _prev_velocity.y <= 0 and not _stuck_crouching:
				play_animation("fall")
				_crouching = false

	_was_airborne = not is_on_floor()
	
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.collision_layer & 16 != 0:
			die(-collision.normal)
			break

	_grapnel.update_pos()


func set_grapnel(node):
	_grapnel = node
	_grapnel.set_origin(_hook_origin)
	_grapnel.set_player(self)


func _on_Grapnel_hit():
	_pulling = true


func _on_Grapnel_retract():
	_pulling = false


func _on_Sprite_frame_changed():
	var _origin_pos = _grapnel_origins[_sprite.frame_coords]
	if _origin_pos == null:
		_grapnel.hook_visible = false
	else:
		_grapnel.hook_visible = visible
		_hook_origin.position = Vector2(_origin_pos.x, _origin_pos.y)
		var angle = int(_origin_pos.z)
		if _flipped and angle % 180 != 90:
			angle = (540 - angle) % 360
		_grapnel.hold_angle(angle)


func go_to(position: Vector2, flipped = false):
	control_enabled = false
	if _grapnel.active:
		_grapnel.retract()
	_target_pos = position
	_target_flipped = flipped
	_looking = Vector2.ZERO


func _autowalk(delta):
	var _walkdir = 0
	if abs(position.x - _target_pos.x) < _autowalk_snap_prox:
		_flipped = _target_flipped
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
	_grapnel.hook_visible = visible


func die(direction: Vector2):
	var collision = move_and_collide(direction * 25, true, true, true)
	_death_particles.position = Vector2.ZERO if collision == null else collision.position - position
	_death_particles.process_material.direction = -Vector3(direction.x, direction.y, 0)
	_death_particles.process_material.initial_velocity = max(_prev_velocity.length() / 2, 80)
	_velocity = Vector2.ZERO
	_death_sound.volume_db = (max(_prev_velocity.length(), 160) - _max_velocity) / 10
	_death_sound.play()
	
	_grapnel.retract_immediately()
	play_animation("death")


func respawn():
	stand_on(spawnpoint)
	if _flipped:
		scale.x = -1
	_flipped = false


func stand_on(place: Vector2):
	position = place + Vector2(0, -_feet_offset)


func _set_player_visible(value: bool):
	player_visible = value
	_sprite.visible = value
	_grapnel.hook_visible = value


func inch(dir: float):
	if not test_move(transform, Vector2(dir, 0)):
		position.x += dir
