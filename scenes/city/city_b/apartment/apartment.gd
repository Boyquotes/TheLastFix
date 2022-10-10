extends Node2D

var _tony_awake = false

onready var _cutscene_animator = $CutsceneAnimator
onready var cam_target = $CamTarget
onready var _cam_start = $CamStart

var _player: Player
var _screen: Screen

func _ready():
	_screen = $".."


func _on_TonySeeArea_body_entered(body):
	if body is Player and not _tony_awake:
		Game._current_level.followed_node = null
		Game._current_level.camera.position = Vector2(-20, 0)
		body._grapnel.retract()
		body.go_to($TonySeeArea/StopPos.global_position, true)
		_tony_awake = true
		_cutscene_animator.play("tony_wakeup")


func cam_follow_player():
	Game._current_level.followed_node = Game.get_player()


func _process(_delta):
	if _screen.active and not _tony_awake:
		if _player == null:
			_player = Game.get_player()
		
		var pos = _player.position
		pos.x += (pos.x - _cam_start.global_position.x) * 0.5
		cam_target.global_position = pos
