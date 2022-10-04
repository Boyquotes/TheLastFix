extends Node2D

onready var _animation_player = $AnimationPlayer
onready var _floor_1 = $Interior/Floors/Floor_1
onready var _floor_2 = $Interior/Floors/Floor_2
onready var _walls = $Interior/Walls
onready var _occluder = $Interior/Walls/Occluder
onready var _floor_shadow = $Interior/GroundFloor/FloorShadow
onready var _exterior = $Exterior
onready var _shadow = $Shadow

var _player: Player

var _floors = []


func _ready():
	for i in range(1, 9):
		_floors.append(get_node("Interior/Floors/Floor_" + str(i)))
	$Facade/CatAnimation.play("wag")


func _on_InteriorArea_body_entered(body):
	if body is Player:
		body._grapnel.retract_immediately()
		body.snap_to_floor = true
		for f in _floors:
			f.enabled = true
		_walls.collision_layer = 2
		_occluder.light_mask = 1
		_floor_shadow.range_item_cull_mask = 1
		_animation_player.play("enter")
		_exterior.z_index = 20


func _on_InteriorArea_body_exited(body):
	if body is Player:
		body._grapnel.retract()
		body.snap_to_floor = false
		for f in _floors:
			f.enabled = false
		_walls.collision_layer = 0
		_occluder.light_mask = 0
		_floor_shadow.range_item_cull_mask = 0
		_animation_player.play("exit")
		_exterior.z_index = -10


func _process(_delta):
	if _player == null:
		_player = Game.get_player()
	_shadow.visible = _player.position.x > _shadow.global_position.x
	_shadow.global_scale.x = (_player.position.x - _shadow.global_position.x) / 10

