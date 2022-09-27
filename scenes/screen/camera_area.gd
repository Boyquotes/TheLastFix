extends Area2D

class_name CameraArea


var _level: Level
var _screen = null
var _active = false

export var limits: Rect2


func _physics_process(_delta):
	var _was_active = _active
	_active = false
	for body in get_overlapping_bodies():
		if body is Player:
			_active = true

	if _active and not _was_active:
		_level.add_cam_limits(limits)
	elif _was_active and not _active and _screen.active:
		_level.remove_cam_limits(limits)


func set_level(level: Level):
	_level = level


func set_screen(screen):
	_screen = screen
	limits.position += screen.global_position
