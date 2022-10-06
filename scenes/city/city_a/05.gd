extends Screen


func load_as_first(_player, _spawnpoint: Vector2, end_cutscenes: bool):
	.load_as_first(_player, _spawnpoint, end_cutscenes)
	if end_cutscenes:
		_player.stand_on($FireHydrant/FixingPosition.global_position)
		finish()


func finish():
	$FireHydrant/AnimationPlayer.stop()
	$FireHydrant/Particles2D.emitting = false
	$FireHydrant/Sprite.frame_coords = Vector2(8, 1)
	$FireHydrant/Prompt._used = true
	$FireHydrant/Prompt.visible = false
	_set_block_right(false)
