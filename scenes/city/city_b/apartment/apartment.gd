extends Node2D

var _tony_awake = false

@onready var _cutscene_animator = $CutsceneAnimator
@onready var cam_target = $CamTarget
@onready var _tony_player = $TonyPlayer

var _player: Player
var _screen: Screen

func _ready():
	_screen = $".."
	_tony_player.play("sleep")


func _on_TonySeeArea_body_entered(body):
	if body is Player and not _tony_awake:
		body.grapnel.retract()
		body.go_to($TonySeeArea/StopPos.global_position, true)
		_tony_awake = true
		_cutscene_animator.play("tony_wakeup")


func _process(_delta):
	if _screen.active:
		if _player == null:
			_player = Game.get_player()
		
		cam_target.global_position = _player.position + Vector2(-50, 0)


func _on_Fridge_tony_angered(level: int):
	match level:
		0:
			_tony_player.play("get_up")
		1:
			_tony_player.play("point")
		2:
			_tony_player.play("drink")
		3:
			_tony_player.play("pullout_gun")
		4:
			_tony_player.play("gun_idle")
		5:
			_player.inching = true
			_player.visible = true
			_player.control_enabled = true
			_player.grapnel_enabled = false
			_player._sprite.frame_coords = Vector2(0, 15)
			
			_cutscene_animator.play("enable_prompt")
			$Tony/Barrier.collision_layer = 4
			$Tony/Barrier.collision_mask = 1
			$Tony/BackoutArea/Collision.disabled = false
			_tony_player.play("gun_idle")


func _on_gun_grab():
	Game.fade_out(1)
	var error = Game.connect("fade_finished", self.end_of_demo, CONNECT_ONE_SHOT)
	assert(error == 0) #,"Error connecting fade_finished: " + str(error))


func end_of_demo():
	Game.load_level(load("res://scenes/demo_end/demo_end.tscn"))


func _on_BackoutArea_body_entered(body):
	if body is Player:
		_on_gun_grab()
