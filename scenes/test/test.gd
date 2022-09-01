extends PlayableLevel


func _on_DeathArea_body_entered(body):
	if body is Player:
		call_deferred("reload")
