extends Node2D

var _tony_awake = false

onready var _cutscene_animator = $CutsceneAnimator


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
