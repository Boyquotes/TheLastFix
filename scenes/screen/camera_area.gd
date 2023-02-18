extends Area2D

class_name CameraArea


var _level: Level
var _screen = null
var _active = false

@export var limits: Rect2
@export var offset: Vector2

var _state: CameraState


func _ready():
	_state = CameraState.new()
	_state.limits = limits
	_state.offset = offset


func _physics_process(_delta):
	var _was_active = _active
	_active = false
	for body in get_overlapping_bodies():
		if body is Player:
			_active = true

	if _active and not _was_active:
		_level.add_cam_state(_state)
	elif _was_active and not _active:
		_level.remove_cam_state(_state)


func set_level(level: Level):
	_level = level


func set_screen(screen):
	_screen = screen
	_state.limits.position += screen.global_position
