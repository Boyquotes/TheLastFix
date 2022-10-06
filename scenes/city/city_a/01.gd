extends Screen


func load_as_first(_player, _spawnpoint: Vector2, end_cutscenes: bool):
	_level._cutscene_player.play("intro")
	_level.followed_node = null
	if end_cutscenes:
		_level._cutscene_player.seek(_level._cutscene_player.current_animation_length)
		_player.play_idle()
		_level.cam_follow_player()
		_level.camera.drag_margin_h_enabled = true
