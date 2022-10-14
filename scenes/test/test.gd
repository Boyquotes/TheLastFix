extends PlayableLevel


func _ready():
	Game.set_zoom(0.1, _player.position + Vector2(0, 20))
	Game.zoom_out(1)


func _on_DeathArea_body_entered(body):
	if body is Player:
		call_deferred("reload")
