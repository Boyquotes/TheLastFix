extends Node2D

var _tony_awake = false

onready var _cutscene_animator = $CutsceneAnimator
onready var cam_target = $CamTarget

var _player: Player
var _screen: Screen

func _ready():
	_screen = $".."


func _on_TonySeeArea_body_entered(body):
	if body is Player and not _tony_awake:
		body._grapnel.retract()
		body.go_to($TonySeeArea/StopPos.global_position, true)
		_tony_awake = true
		_cutscene_animator.play("tony_wakeup")


func cam_follow_player():
	Game._current_level.followed_node = Game.get_player()
	Game._current_level.camera.drag_margin_h_enabled = true
	Game._current_level.camera.smoothing_enabled = true


func _process(_delta):
	if _screen.active and not _tony_awake:
		if _player == null:
			_player = Game.get_player()
		
		cam_target.global_position = _player.position + Vector2(-50, 0)
