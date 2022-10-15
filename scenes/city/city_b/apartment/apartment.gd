extends Node2D

var _tony_awake = false

onready var _cutscene_animator = $CutsceneAnimator
onready var cam_target = $CamTarget
onready var _tony_player = $TonyPlayer

var _player: Player
var _screen: Screen

func _ready():
	_screen = $".."
	_tony_player.play("sleep")


func _on_TonySeeArea_body_entered(body):
	if body is Player and not _tony_awake:
		body._grapnel.retract()
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


func _on_Fridge_finished_fixing():
	_tony_player.play("gun_idle")
