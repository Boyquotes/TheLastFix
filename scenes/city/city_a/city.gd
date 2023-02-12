extends PlayableLevel


func _ready():
	super()
	if start_at_screen.is_empty():
		followed_node = null
		$CutsceneAnimator.play("intro")


func cam_follow_player():
	followed_node = _player
