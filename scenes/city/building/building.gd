extends Node2D

onready var _animation_player = $AnimationPlayer
onready var _floor_1 = $Interior/Floors/Floor_1
onready var _floor_2 = $Interior/Floors/Floor_2
onready var _walls = $Interior/Walls
onready var _occluder = $Interior/Walls/Occluder
onready var _floor_shadow = $Interior/GroundFloor/FloorShadow


func _ready():
	pass # Replace with function body.


func _on_InteriorArea_body_entered(body):
	if body is Player:
		_floor_1.enabled = true
		_floor_2.enabled = true
		_walls.collision_layer = 2
		_occluder.light_mask = 1
		_floor_shadow.range_item_cull_mask = 1
		_animation_player.play("enter")


func _on_InteriorArea_body_exited(body):
	if body is Player:
		_floor_1.enabled = false
		_floor_2.enabled = false
		_walls.collision_layer = 0
		_occluder.light_mask = 0
		_floor_shadow.range_item_cull_mask = 0
		_animation_player.play("exit")
