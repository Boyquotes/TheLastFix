extends Node2D

class_name Screen


onready var _screen_area = $ScreenArea
onready var _collision_area = $ScreenArea/CollisionArea

var _level = null


func set_level(level):
	_level = level


func _on_ScreenArea_body_entered(_body):
	_level.set_active_screen(self)


func get_extents() -> Rect2:
	return Rect2(position - _collision_area.shape.extents, _collision_area.shape.extents * 2)
