extends Area2D

class_name CameraArea


var _level: Level
var _screen = null
var _prev_limits: Rect2
var _active = false

export var limits: Rect2


func _physics_process(_delta):
	var _was_active = _active
	_active = false
	for body in get_overlapping_bodies():
		if body is Player:
			_active = true

	if _active and not _was_active:
		_prev_limits = get_camera_limits(_level.camera)
		set_camera_limits(_level.camera, limits)
	elif _was_active and not _active and _screen.active:
		set_camera_limits(_level.camera, _prev_limits)


func set_level(level: Level):
	_level = level


func set_screen(screen):
	_screen = screen
	limits.position += screen.global_position


func get_camera_limits(camera: Camera2D) -> Rect2:
	return Rect2(camera.limit_left, camera.limit_top, camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)


func set_camera_limits(camera: Camera2D, limit: Rect2):
	var edge_1 = limit.position
	var edge_2 = limit.end
	camera.limit_left = int(edge_1.x)
	camera.limit_top = int(edge_1.y)
	camera.limit_right = int(edge_2.x)
	camera.limit_bottom = int(edge_2.y)
