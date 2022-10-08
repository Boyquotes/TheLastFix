extends PlayableLevel


func _ready():
	if start_at_screen.empty():
		followed_node = null
		_cutscene_player.play("intro")


func cam_follow_player():
	followed_node = _player
