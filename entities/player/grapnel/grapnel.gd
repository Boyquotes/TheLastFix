extends CharacterBody2D

class_name Grapnel


signal hit()
signal retracted()

const _shoot_speed = 250
const _pull_speed = 30
const _grapple_suck_dist = 5

var _held_angle = 0
@export var angle = 0
var _retracting = false
var _origin = null
var _player = null
var _prev_joints = PackedVector2Array()
var _joints = PackedVector2Array()
var _pushoff = Vector2.ZERO
var _first_joint_offset = Vector2.ZERO

var _origin_stuck_frames = -1
var _prev_player_pos = Vector2.ZERO
var _prev_origin_pos = Vector2.ZERO

@onready var _sprite = $Sprite2D
@onready var _collision = $Collision
@onready var _particles = $Particles
@onready var _light = $Light3D
@onready var _shoot_sound = $ShootSound
@onready var _latch_sound = $LatchSound
@onready var _vine_sound = $VineSound
@onready var _hit_sound = $HitSound
@onready var _zip_sound = $ZipSound

@export var active = false
@export var stuck = false
@export var hit_angle = 0
@export var hook_visible = true : set = _set_hook_visible

var chain_texture = preload("res://entities/player/grapnel/chain.png")
var chain_1 = null
var chain_2 = null

var physics_query: PhysicsShapeQueryParameters2D


func _ready():
	chain_1 = AtlasTexture.new()
	chain_1.atlas = chain_texture
	chain_1.region = Rect2(0, 0, 3, 3)

	chain_2 = AtlasTexture.new()
	chain_2.atlas = chain_texture
	chain_2.region = Rect2(3, 0, 3, 3)
	
	physics_query = PhysicsShapeQueryParameters2D.new()
	physics_query.set_shape(_collision.shape)
	physics_query.collision_mask = 2 | 8
	
	var error = Game.connect("player_light_changed",Callable(self,"_set_player_light"))
	assert(error == 0)


func _set_player_light(energy: float):
	_light.energy = energy * 0.7


func _set_hook_visible(value: bool):
	hook_visible = value
	if _sprite != null:
		_sprite.visible = value
		_light.enabled = value


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
	physics_query.transform = transform
	physics_query.transform.origin = _origin.global_position - direction * 1.5

	var space_state = get_world_2d().direct_space_state
	var intersects = space_state.intersect_shape(physics_query)
	
	if not intersects.is_empty():
		position = _player.position - direction * 1.5
	else:
		position = _origin.global_position

	velocity = direction
	_sprite.frame = 1 if velocity.x != 0 and velocity.y != 0 else 0
	rotation = -velocity.angle_to(Vector2.RIGHT if _sprite.frame != 1 else Vector2(1, -1))
	
	_first_joint_offset = Vector2(0, 3).rotated(rotation) if _sprite.frame == 1 else Vector2.ZERO
	
	_particles.rotation = velocity.angle() - rotation + PI
	_collision.set_deferred("disabled", false)
	_joints.resize(0)
	_joints.push_back(position)
	_joints.push_back(position)
	_prev_joints = PackedVector2Array(_joints)
	_prev_player_pos = _player.position
	_pushoff = Vector2.ZERO

	active = true
	_retracting = false
	visible = true
	_shoot_sound.play_rand()


func retract():
	_retracting = true
	_collision.set_deferred("disabled", true)
	queue_redraw()
	emit_signal("retracted")
	if stuck:
		_player.play_idle(false)
	stuck = false


func retract_immediately():
	if not _retracting:
		emit_signal("retracted")
		_retracting = false

	_collision.set_deferred("disabled", true)
	_joints.resize(0)
	_particles.emitting = false
	queue_redraw()
	
	if stuck:
		_player.play_idle(false)
	active = false
	stuck = false
	
	hold_angle(_held_angle)


func get_pull(origin: Vector2, player_velocity: Vector2) -> Vector2:
	var dist = (_joints[-2] if _joints.size() >= 3 else position) - origin
	
	# In rare cases the player may be directed towards a joint created purely due to the grapnel
	# origin's visual positioning. In such a case, to prevent this causing the player to get stuck
	# checked a wall, the direction of the pull is altered to direct them immediately to the next joint.
	if _joints.size() > 2:
		var space_state = get_world_2d().direct_space_state
		var params = PhysicsRayQueryParameters2D.new()
		params.from = origin
		params.to = _joints[-3]
		params.exclude = [self]
		params.collision_mask = 2
		if space_state.intersect_ray(params).is_empty():
			dist = _joints[-3] - origin
	
	var pull = dist.normalized() * _pull_speed + _pushoff * 45
	_pushoff = Vector2.ZERO
	if dist.length() < _grapple_suck_dist:
		pull -= player_velocity
	return pull


func _physics_process(delta):
	var zipping = active and not stuck
	if _zip_sound.playing != zipping:
		_zip_sound.playing = zipping
	if not active:
		return

	var space_state = get_world_2d().direct_space_state
	
	_joints[0] = position + _first_joint_offset
	var origin_pos = _origin.global_position + 2 * Vector2.LEFT.rotated(-_held_angle / 180.0 * PI)
	_joints[-1] = _player.position if _origin_stuck_frames >= 0 else origin_pos

	if _retracting:
		if _joints.size() <= 2:
			var dist = _joints[1] - position
			position += dist.normalized() * max(min(dist.length(), 8), 4)
		else:
			position += (_joints[1] - position).normalized() * 8
		if position.distance_to(_joints[1]) < 10:
			position = _joints[1]
			_joints.remove_at(1)
			if _joints.size() <= 1:
				retract_immediately()
				return
	else:
		var params = PhysicsPointQueryParameters2D.new()
		params.position = position
		params.exclude = [self]
		params.collision_mask = 32
		params.collide_with_bodies = false
		params.collide_with_areas = true
		var intersect = space_state.intersect_point(params, 1)
		if intersect.is_empty():
			retract()
			return
		
		var collision = move_and_collide(velocity * _shoot_speed * delta)
		
		if collision != null:
			var new_pos = position - collision.get_normal() * 2
			# If the tile hit belongs to the non_grapnel layer, retract the grapnel
			physics_query.transform = transform
			_hit_sound.play_rand()
			
			physics_query.transform.origin = new_pos
			physics_query.collision_mask = 8
			var intersects = space_state.intersect_shape(physics_query)
			physics_query.collision_mask = 2 | 8
			
			if not intersects.is_empty():
				_vine_sound.play_rand()
				retract()
				return
			
			_latch_sound.play_rand()
			_particles.emitting = true
			_particles.restart()
			hit_angle = -round((-collision.get_normal()).angle() * 180 / PI)
			stuck = true
			emit_signal("hit")
			_collision.disabled = true
			position = new_pos
			velocity = Vector2.ZERO
	
	var params = PhysicsPointQueryParameters2D.new()
	params.position = origin_pos
	params.exclude = [self]
	params.collision_mask = 2
	if not space_state.intersect_point(params, 1).is_empty():
		if _origin_stuck_frames < 0:
			_joints[-1] = _prev_player_pos
			_make_joints(_joints.size() - 1, space_state)
			_prev_joints = PackedVector2Array(_joints)
		_joints[-1] = _player.position
		_origin_stuck_frames = 0
	elif _origin_stuck_frames >= 0:
		_origin_stuck_frames += 1
		if _origin_stuck_frames >= 2:
			_origin_stuck_frames = -1
			_joints[-1] = origin_pos

	_make_joints(_joints.size() - 1, space_state)
	if velocity != Vector2.ZERO:
		_make_joints(1, space_state)

	_prev_joints = PackedVector2Array(_joints)

	_remove_joints(space_state)
	
	_prev_player_pos = _player.position
	_prev_origin_pos = origin_pos


func round_to_tile(point: Vector2):
	return (point / 8).round() * 8


func _make_joints(index: int, space_state: PhysicsDirectSpaceState2D):
	var origin = _joints[index]
	var target = _joints[index - 1]

	var ray_params = PhysicsRayQueryParameters2D.new()
	ray_params.from = origin
	ray_params.to = target
	ray_params.exclude = [self]
	ray_params.collision_mask = 2

	var colliding_ray = space_state.intersect_ray(ray_params)
	if colliding_ray.is_empty():
		#print("Ray ", origin, " -> ", target, " is clear")
		return
	#print("Origin: ", _prev_joints[index], " -> ", origin)
	#print("Target: ", _prev_joints[index - 1], " -> ", target)

	# Perform a binary search checked raycasting to approximate the edge
	var clear_origin_end = _prev_joints[index]
	var clear_target_end = _prev_joints[index - 1]
	var obscured_origin_end = origin
	var obscured_target_end = target
	var middle_origin = (clear_origin_end + obscured_origin_end) / 2
	var middle_target = (clear_target_end + obscured_target_end) / 2
	
	ray_params.from = clear_origin_end
	ray_params.to = clear_target_end
	var previous_ray = space_state.intersect_ray(ray_params)
	if not previous_ray.is_empty():
		print("ERROR: Previous ray (", clear_origin_end, " -> ", clear_target_end, ") not clear!")
		return
	

	var opposite_ray = null
	for _i in 20:
		ray_params.from = middle_origin
		ray_params.to = middle_target
		var result = space_state.intersect_ray(ray_params)
		#print(middle_origin, middle_target)
		if result.is_empty():
			clear_origin_end = middle_origin
			clear_target_end = middle_target
			middle_origin = (middle_origin + obscured_origin_end) / 2
			middle_target = (middle_target + obscured_target_end) / 2
		else:
			ray_params.from = middle_target
			ray_params.to = middle_origin
			var opposite_ray_candidate = space_state.intersect_ray(ray_params)
			
			# If the opposite ray candidate fails either of these tests,
			# it typically means the binary search was TOO accurate,
			# to the point where the normals can't be calculated.
			var params = PhysicsPointQueryParameters2D.new()
			params.position = middle_target
			params.exclude = [self]
			params.collision_mask = 2
			if opposite_ray_candidate.is_empty():
				#print("Stopping raycasting search (no opposite ray found) after ", _i, " iterations")
				break

			if opposite_ray_candidate.normal.dot(result.normal) != 0 and opposite_ray_candidate.position.distance_to(result.position) < 1:
				#print("Stopping raycasting search (normals aren't perpendicular) after ", _i, " iterations")
				break

			obscured_origin_end = middle_origin
			obscured_target_end = middle_target
			middle_origin = (middle_origin + clear_origin_end) / 2
			middle_target = (middle_target + clear_target_end) / 2
			colliding_ray = result
			opposite_ray = opposite_ray_candidate
			

	if opposite_ray == null:  # Really shouldn't happen
		print("ERROR: No opposite ray found")
		return

	# colliding_ray is now the most precise edge ray that intersects the tile
	var normal_1: Vector2 = colliding_ray.normal
	var normal_2: Vector2 = opposite_ray.normal
	if normal_1.dot(normal_2) != 0:
		print("FAILED: Normals not perpendicular")
		return

	var edge = round_to_tile((colliding_ray.position + opposite_ray.position) / 2)

	edge += (normal_1 + normal_2) * 1.5
	_joints.insert(index, edge)


func _remove_joints(space_state: PhysicsDirectSpaceState2D):
	if _joints.size() < 3:
		return

	var prev = _joints[-3]
	var mid = _joints[-2]
	var next = _joints[-1]
	
	var edge_normal = ((next - mid).normalized() + (prev - mid).normalized()).sign()
	
	var params = PhysicsPointQueryParameters2D.new()
	params.position = mid + edge_normal * 3
	params.exclude = [self]
	params.collision_mask = 2
	var intersections = space_state.intersect_point(params, 1)
	if intersections.is_empty():
		var edge = _joints[-2]
		_pushoff = edge - round_to_tile(edge)
		_joints.remove_at(_joints.size() - 2)


func _process(_delta):
	if active:
		queue_redraw()
	else:
		update_pos()


func update_pos():
	if not active:
		position = _origin.global_position


func _draw():
	if not active or not hook_visible:
		return

	var prev_joint = position + _first_joint_offset
	var even = false
	for i in range(1, _joints.size()):
		var joint = _joints[i]
		var target = joint - prev_joint

		draw_set_transform(
			(prev_joint - position - Vector2(1.5, 1.5).rotated(target.angle())).round().rotated(-rotation),
			target.angle() - rotation,
			Vector2(1, 1)
		)
		prev_joint = joint

		if target.length() < 1:
			continue

		for j in range(0, target.length(), 3):
			draw_texture(chain_1 if even else chain_2, Vector2.RIGHT * j)
			even = not even


func set_origin(origin):
	_origin = origin


func set_player(player):
	_player = player
