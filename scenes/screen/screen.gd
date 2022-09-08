extends Node2D

class_name Screen


onready var _screen_area = $ScreenArea
onready var _collision_area = $ScreenArea/CollisionArea

var _level = null

export var active = false
export var spawnpoint = Vector2.ZERO


func set_level(level):
	_level = level


func _on_ScreenArea_body_entered(body):
	if body is Player:
		_level.set_active_screen(self)
		body.position += body.get_velocity().normalized() * 5
	elif body is Grapnel and body.active and not active:
		body.retract()


func _on_ScreenArea_body_exited(body):
	if body is Grapnel and body.active and not body.stuck:
		body.retract()


func get_extents() -> Rect2:
	return Rect2(position - _collision_area.shape.extents, _collision_area.shape.extents * 2)
