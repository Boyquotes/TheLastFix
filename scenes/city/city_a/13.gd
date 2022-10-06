extends Screen


func load_as_first(_player, _spawnpoint: Vector2, end_cutscenes: bool):
	.load_as_first(_player, _spawnpoint, end_cutscenes)
	if end_cutscenes:
		$".."._spoke_to_frankie = true
		_player.stand_on($"Building/FrankieTalkPos".global_position)
