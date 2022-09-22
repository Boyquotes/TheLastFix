extends Node2D

class_name Screen


onready var _screen_area = $ScreenArea
onready var _collision_area = $ScreenArea/CollisionArea

onready var _left_blocker: CollisionShape2D = $Blockers/Left
onready var _right_blocker: CollisionShape2D = $Blockers/Right
onready var _top_blocker: CollisionShape2D = $Blockers/Top
onready var _bottom_killer: CollisionShape2D = $DeathArea/Bottom

var _level = null

export var active = false
export var spawnpoints: PoolVector2Array

export var block_left = false setget _set_block_left
export var block_right = false setget _set_block_right
export var block_top = true setget _set_block_top
export var kill_bottom = true setget _set_kill_bottom


func set_level(level):
	_level = level
	for child in get_children():
		if child is CameraArea:
			child.set_level(level)
			child.set_screen(self)


func _on_ScreenArea_body_entered(body):
	if body is Player:
		_level.set_active_screen(self)
		body.position += body.get_velocity().normalized() * 5
		flush_blockers()
	elif body is Grapnel and body.active and not active:
		body.retract()


func _on_ScreenArea_body_exited(body):
	if body is Grapnel and body.active and not body.stuck:
		body.retract()


func get_extents() -> Rect2:
	return Rect2(position - _collision_area.shape.extents, _collision_area.shape.extents * 2)


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


func on_enter_death_area(body):
	if body is Player:
		_level.fall_from_screen()


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
