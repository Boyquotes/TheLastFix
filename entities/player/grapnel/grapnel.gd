extends KinematicBody2D

class_name Grapnel


signal hit(position)

const _shoot_speed = 300
const _pull_speed = 30
const _grapple_suck_dist = 5

var _held_angle = 0
export var angle = 0
var _velocity = Vector2.ZERO
var _origin = null
var _prev_origin_point = Vector2.ZERO
var _prev_target_point = Vector2.ZERO
var _joints = PoolVector2Array()
var _pushoff = Vector2.ZERO

onready var _sprite = $Sprite
onready var _collision = $Collision
onready var _particles = $Particles
onready var _hitbox_area = $HitboxArea

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
	if not _hitbox_area.get_overlapping_bodies().empty():
		return

	_velocity = direction
	_sprite.frame = 1 if _velocity.x != 0 and _velocity.y != 0 else 0
	rotation = -_velocity.angle_to(Vector2.RIGHT if _sprite.frame != 1 else Vector2(1, -1))
	_particles.rotation = _velocity.angle() - rotation + PI
	_collision.disabled = false
	_joints.push_back(position)
	_joints.push_back(position)
	_prev_origin_point = position
	_prev_target_point = position
	_pushoff = Vector2.ZERO

	active = true
	visible = true


func retract():
	active = false
	_particles.visible = false
	_collision.disabled = true
	hold_angle(_held_angle)
	_joints.resize(0)
	update()


func get_pull(origin: Vector2, velocity: Vector2):
	var dist = _joints[-2] - origin
	var pull = dist.normalized() * _pull_speed + _pushoff * 45
	_pushoff = Vector2.ZERO
	if dist.length() < _grapple_suck_dist:
		pull -= velocity
	return pull


func _physics_process(delta):
	if not active:
		return

	var collision = move_and_collide(_velocity * _shoot_speed * delta)
	if collision != null:
		_particles.visible = true
		_particles.emitting = true
		_particles.restart()
		hit_angle = -round((-collision.normal).angle() * 180 / PI)
		emit_signal("hit", collision.position)
		_collision.disabled = true
		position += _velocity * 2
		_velocity = Vector2.ZERO

	_joints[0] = position
	_joints[-1] = _origin.global_position + 2 * Vector2.LEFT.rotated(-_held_angle / 180.0 * PI)
	
	var space_state = get_world_2d().direct_space_state
	_make_joints(space_state)

	_prev_origin_point = _joints[-1]
	_prev_target_point = _joints[-2]

	_remove_joints(space_state)


func round_to_tile(point: Vector2):
	point.x = round(point.x / 8) * 8
	point.y = round(point.y / 8) * 8
	return point


func _make_joints(space_state: Physics2DDirectSpaceState):
	var origin = _joints[-1]
	var target = _joints[-2]
	if not space_state.intersect_point(origin, 1, [self], 2).empty():
		return

	var colliding_ray = space_state.intersect_ray(origin, target, [self], 2)
	if colliding_ray.empty():
		return
	#print("Origin: ", _prev_origin_point, " -> ", origin)
	#print("Target: ", _prev_target_point, " -> ", target)

	# Perform a binary search on raycasting to approximate the edge
	var clear_origin_end = _prev_origin_point
	var clear_target_end = _prev_target_point
	var obscured_origin_end = origin
	var obscured_target_end = target
	var middle_origin = (clear_origin_end + obscured_origin_end) / 2
	var middle_target = (clear_target_end + obscured_target_end) / 2
	
	var previous_ray = space_state.intersect_ray(clear_origin_end, clear_target_end, [self], 2)
	if not previous_ray.empty():
		print("ERROR: Previous ray not clear!")
		return
	

	var opposite_ray = null
	for _i in range(20):
		var result = space_state.intersect_ray(middle_origin, middle_target, [self], 2)
		#print(middle_origin, middle_target)
		if result.empty():
			clear_origin_end = middle_origin
			clear_target_end = middle_target
			middle_origin = (middle_origin + obscured_origin_end) / 2
			middle_target = (middle_target + obscured_target_end) / 2
		else:
			var opposite_ray_candidate = space_state.intersect_ray(middle_target, middle_origin, [self], 2)
			
			# If the opposite ray candidate fails either of these tests,
			# it typically means the binary search was TOO accurate,
			# to the point where the normals can't be calculated. 
			if opposite_ray_candidate.empty():
				print("Stopping raycasting search (no opposite ray found) after ", _i, " iterations")
				break

			if opposite_ray_candidate.normal.dot(result.normal) != 0 and opposite_ray_candidate.position.distance_to(result.position) < 1:
				print("Stopping raycasting search (normals aren't perpendicular) after ", _i, " iterations")
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
		print(_prev_origin_point, _joints[-1], middle_origin, middle_target, normal_1, normal_2, colliding_ray.position, opposite_ray.position)
		return

	var edge = round_to_tile((colliding_ray.position + opposite_ray.position) / 2)

	edge += (normal_1 + normal_2) * 1.5
	_joints.insert(_joints.size() - 1, edge)


func _remove_joints(space_state: Physics2DDirectSpaceState):
	if _joints.size() < 3:
		return

	var prev = _joints[-3]
	var mid = _joints[-2]
	var next = _joints[-1]
	
	var edge_normal = ((next - mid).normalized() + (prev - mid).normalized()).sign()
	var intersections = space_state.intersect_point(mid + edge_normal * 3, 1, [self], 2)
	if intersections.empty():
		var edge = _joints[-2]
		_pushoff = edge - round_to_tile(edge)
		_joints.remove(_joints.size() - 2)


func _process(_delta):
	if active:
		update()
	else:
		position = _origin.global_position


func _draw():
	if not active:
		return

	var prev_joint = _joints[0]
	var even = false
	for i in range(1, _joints.size()):
		var joint = _joints[i]
		var target = joint - prev_joint

		draw_set_transform(
			(prev_joint - position - Vector2(1.5, 1.5).rotated(target.angle())).rotated(-rotation),
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
