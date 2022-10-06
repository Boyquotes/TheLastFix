extends Screen


func load_as_first(_player, _spawnpoint: Vector2, end_cutscenes: bool):
	.load_as_first(_player, _spawnpoint, end_cutscenes)
	if end_cutscenes:
		_player.stand_on($"Bar/Bar Sign/FixingPosition".global_position)
		finish()


func finish():
	$"Bar/Bar Sign/AnimationPlayer".stop()
	$"Bar/Bar Sign/Sprite".frame = 1
	$"Bar/Bar Sign/Prompt"._used = true
	$"Bar/Bar Sign/Prompt".visible = false
	_set_block_right(false)
