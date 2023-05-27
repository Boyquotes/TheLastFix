extends Node2D

@onready var _animator = $Animator
@onready var _walls = $Interior/Walls
@onready var _occluder = $Interior/Walls/Occluder
@onready var _floor_shadow = $Interior/GroundFloor/FloorShadow
@onready var _exterior = $Exterior
@onready var _shadow = $Shadow
@onready var _mask = $Mask



var _player: Player
var spoke_to_frankie = false
var _next_level_path = ""
var _player_prev_parent = null

var _floors = []


func _ready():
	for i in range(1, 9):
		_floors.append(get_node("Interior/Floors/Floor_" + str(i)))
	$Facade/CatAnimation.play("wag")
	$Facade/Frankie.play("default")


func _on_InteriorArea_body_entered(body):
	if body is Player and body.get_parent() != _mask:
		body.grapnel.retract_immediately()
		body.snap_to_floor = true
		for f in _floors:
			f.enabled = true
		_walls.collision_layer = 2
		_occluder.visible = true
		_floor_shadow.range_item_cull_mask = 1
		_animator.play("enter")
		
		_player_prev_parent = body.get_parent()
		Game.set_player_light(1, 0)
		
		body.grapnel.z_index = 0
		body.grapnel.call_deferred("reparent", _mask)
		
		body.z_index = 0
		body.call_deferred("reparent", _mask)


func _on_InteriorArea_body_exited(body):
	if body is Player and body.get_parent() == _mask:
		body.grapnel.retract()
		body.snap_to_floor = false
		for f in _floors:
			f.enabled = false
		_walls.collision_layer = 0
		_occluder.visible = false
		_floor_shadow.range_item_cull_mask = 0
		_animator.play("exit")
		_exterior.z_index = -10
		
		Game.set_player_light(1)
		
		body.grapnel.z_index = -2
		body.grapnel.call_deferred("reparent", _player_prev_parent)
		
		body.z_index = -1
		body.call_deferred("reparent", _player_prev_parent)


func _process(_delta):
	if _player == null:
		_player = Game.get_player()
	_shadow.enabled = _player.position.x > _shadow.global_position.x
	_shadow.global_scale.x = (_player.position.x - _shadow.global_position.x) / 10


func _on_FrankieTalkArea_body_entered(body):
	if body is Player and not spoke_to_frankie:
		spoke_to_frankie = true
		_player.go_to($FrankieTalkPos.global_position)
		var error = _player.connect("reached_target", _animator.play.bind("meet_frankie"), CONNECT_ONE_SHOT)
		assert(error == 0) #,"Error connecting reached_target: " + str(error))


func _on_6APrompt_used():
	open_apartment($"Interior/6APrompt/Collision", true, "res://scenes/city/city_b/city.tscn")


func _on_PenthousePrompt_used():
	open_apartment($"Interior/PenthousePrompt/Collision", false, "")


func open_apartment(collision: CollisionShape2D, flipped: bool, next_level: String):
	_player.control_enabled = false
	var pos = collision.global_position + Vector2(0, collision.shape.extents.y)
	Game.set_zoom(1, collision.global_position)
	_player.go_to(pos, flipped)
	_next_level_path = next_level
	var error = _player.connect("reached_target", _animator.play.bind("open_door"))
	assert(error == 0) #,"Error connecting reached_target: " + str(error))


func load_next_level():
	Game.load_level(load(_next_level_path))
