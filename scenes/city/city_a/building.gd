extends Screen


func load_as_first(_player, _spawnpoint: Vector2, end_cutscenes: bool):
	super.load_as_first(_player, _spawnpoint, end_cutscenes)
	if end_cutscenes:
		$Building.spoke_to_frankie = true
		_player.stand_on($"Building/FrankieTalkPos".global_position)
