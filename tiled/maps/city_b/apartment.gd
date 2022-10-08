extends Screen


func load_as_first(player, _spawnpoint: Vector2, end_cutscenes: bool):
	player.stand_on($EnterPos.global_position)
