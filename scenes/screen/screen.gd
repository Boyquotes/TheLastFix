@tool
extends Node2D

class_name Screen


@onready var _screen_area = $ScreenArea
@onready var _collision_area = $ScreenArea/CollisionArea

@onready var _left_blocker: CollisionShape2D = $Blockers/Left
@onready var _right_blocker: CollisionShape2D = $Blockers/Right
@onready var _top_blocker: CollisionShape2D = $Blockers/Top
@onready var _bottom_killer: CollisionShape2D = $DeathArea/Bottom

var _level: Level

@export var active = false : set = _set_active

@export var block_left = false : set = _set_block_left
@export var block_right = false : set = _set_block_right
@export var block_top = true : set = _set_block_top
@export var kill_bottom = true : set = _set_kill_bottom
@export var cutscenes_played = false

@export var size = Vector2(256, 144) : set = _set_size
@export var camera_offset = Vector2.ZERO

var _extents: Rect2
var _spawnpoints: Array[Marker2D]
const pushoff_h = 10
const pushoff_v = 20

var cam_state: CameraState


func make_segment_shape(a: Vector2, b: Vector2):
	var segment = SegmentShape2D.new()
	segment.a = a
	segment.b = b
	return segment


func _set_size(_size: Vector2):
	size = _size
	if _collision_area != null:
		var shape = RectangleShape2D.new()
		shape.size = size
		_collision_area.shape = shape
		
		$Blockers.position = -size / 2
		_left_blocker.shape = make_segment_shape(Vector2.ZERO, Vector2(0, size.y))
		_right_blocker.shape = make_segment_shape(Vector2(size.x, 0), size)
		_top_blocker.shape = make_segment_shape(Vector2.ZERO, Vector2(size.x, 0))
		
		$DeathArea.position = -size / 2
		_bottom_killer.shape = make_segment_shape(Vector2(0, size.y), size)


func _ready():
	_set_size(size)
	if Engine.is_editor_hint():
		return

	_extents = Rect2(position - size / 2, size)
	cam_state = CameraState.new()
	cam_state.limits = _extents
	cam_state.offset = camera_offset

	for child in get_children():
		if child is Marker2D and child.name.begins_with("SP"):
			_spawnpoints.append(child)


func set_level(level):
	_level = level
	for child in get_children():
		if child is CameraArea:
			child.set_level(level)
			child.set_screen(self)


func _on_ScreenArea_body_entered(body):
	if body is Player and not active:
		_level.set_active_screen(self)
		
		# Push the player into the screen
		if body.position.x < _extents.position.x:
			body.position.x += pushoff_h
		elif body.position.x > _extents.end.x:
			body.position.x -= pushoff_h
		
		if body.position.y < _extents.position.y:
			body.position.y += pushoff_v
		elif body.position.y > _extents.end.y:
			body.position.y -= pushoff_v

	elif body is Grapnel and body.active and not active:
		body.retract()


func _on_ScreenArea_body_exited(body):
	if body is Player and active:
		_level.set_inactive_screen(self)
		disable_blockers()
	elif body is Grapnel and body.active and not body.stuck:
		body.retract()


func _set_block_left(value: bool):
	block_left = value
	if active:
		flush_blockers()


func _set_block_right(value: bool):
	block_right = value
	if active:
		flush_blockers()


func _set_block_top(value: bool):
	block_top = value
	if active:
		flush_blockers()


func _set_kill_bottom(value: bool):
	kill_bottom = value
	if active:
		flush_blockers()


func flush_blockers():
	_left_blocker.set_deferred("disabled", not block_left)
	_right_blocker.set_deferred("disabled", not block_right)
	_top_blocker.set_deferred("disabled", not block_top)
	_bottom_killer.set_deferred("disabled", not kill_bottom)


func disable_blockers():
	_left_blocker.set_deferred("disabled", true)
	_right_blocker.set_deferred("disabled", true)
	_top_blocker.set_deferred("disabled", true)
	_bottom_killer.set_deferred("disabled", true)


func _set_active(value: bool):
	active = value
	if _screen_area != null:
		_screen_area.set_deferred("monitorable", value)


func load_as_first(player: Player, spawnpoint: Node2D, _end_cutscenes: bool):
	_level.set_active_screen(self)
	if spawnpoint == null:
		if _spawnpoints.is_empty():
			spawnpoint = self
		else:
			spawnpoint = _spawnpoints[0]
			player.spawnpoint = spawnpoint

	player.stand_on(spawnpoint.global_position)

	player.control_enabled = true
	player.visible = true
	player.play_idle()


func get_closest_spawn(pos: Vector2):
	var min_dist = INF
	var closest_spawn = null
	for spawn in _spawnpoints:
		var dist = spawn.global_position.distance_to(pos)
		if dist < min_dist:
			min_dist = dist
			closest_spawn = spawn
	return closest_spawn


func finish():
	pass
