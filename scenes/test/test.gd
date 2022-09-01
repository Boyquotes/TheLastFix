extends PlayableLevel


func _ready():
	zoom_center = _player.position + Vector2(0, 20)
	zoom_level = 0.1
	$StartAnimation.play("start")


func _on_DeathArea_body_entered(body):
	if body is Player:
		call_deferred("reload")
