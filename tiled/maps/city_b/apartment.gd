extends Screen


func load_as_first(player, _spawnpoint: Vector2, _end_cutscenes: bool):
	player.stand_on($EnterPos.global_position)
	Game.set_zoom(0.5625, Vector2(0, -2))
	Game.fade_in(0.5)
	Game.set_player_light(0.0)
	player.scale.x = -1
	player._flipped = true
	player.play_idle()
	
	_level.followed_node = $Apartment.cam_target
	_level.camera.drag_margin_h_enabled = false

