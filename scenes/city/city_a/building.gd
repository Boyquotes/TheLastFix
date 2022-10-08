extends Screen

var _spoke_to_frankie = false
var _next_level_path = ""


func load_as_first(_player, _spawnpoint: Vector2, end_cutscenes: bool):
	.load_as_first(_player, _spawnpoint, end_cutscenes)
	if end_cutscenes:
		_spoke_to_frankie = true
		_player.stand_on($"Building/FrankieTalkPos".global_position)


func _on_FrankieTalkArea_body_entered(body):
	if body is Player and not _spoke_to_frankie:
		_spoke_to_frankie = true
		body._grapnel.retract()
		body.go_to($Building/FrankieTalkPos.global_position)
		var error = body.connect("reached_target", self, "meet_frankie")
		if error != OK:
			print("Error connecting reached_target: ", error)


func meet_frankie():
	Game.get_player().disconnect("reached_target", self, "meet_frankie")
	_level._cutscene_player.play("meet_frankie")


func _on_6APrompt_used():
	open_apartment($"Building/6APrompt/Collision", true, "res://scenes/city/city_b/city.tscn")


func _on_PenthousePrompt_used():
	open_apartment($"Building/PenthousePrompt/Collision", false, "")


func open_apartment(collision: CollisionShape2D, flipped: bool, next_level: String):
	var player = Game.get_player()
	player.control_enabled = false
	var pos = collision.global_position + Vector2(0, collision.shape.extents.y)
	_level.zoom_center = collision.global_position
	player.go_to(pos, flipped)
	_next_level_path = next_level
	player.connect("reached_target", _level._cutscene_player, "play", ["open_door"])


func load_next_level():
	Game.load_level(load(_next_level_path))
