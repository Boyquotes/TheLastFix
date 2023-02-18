@tool
extends Screen


func load_as_first(_player, end_cutscenes: bool):
	super(_player, end_cutscenes)
	if end_cutscenes:
		_player.stand_on($FireHydrant/FixingPosition.global_position)
		finish()


func finish():
	$FireHydrant/AnimationPlayer.stop()
	$FireHydrant/GPUParticles2D.emitting = false
	$FireHydrant/Sprite2D.frame_coords = Vector2(8, 1)
	$FireHydrant/Prompt._used = true
	$FireHydrant/Prompt.visible = false
	$FireHydrant/WaterSound.autoplay = false
	$FireHydrant/WaterSound.stop()
	_set_block_right(false)
	cutscenes_played = true


func _on_FireHydrant_finished_fixing():
	_level.end_cutscenes = true
	_set_block_right(false)
