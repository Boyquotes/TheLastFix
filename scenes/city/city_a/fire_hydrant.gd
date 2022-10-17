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
	$FireHydrant/WaterSound.autoplay = false
	$FireHydrant/WaterSound.stop()
	_set_block_right(false)
	_cutscenes_played = true


func _on_FireHydrant_finished_fixing():
	_level.end_cutscenes = true
	_set_block_right(false)
