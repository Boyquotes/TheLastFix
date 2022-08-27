extends BaseScene


func _on_DeathArea_body_entered(body):
	if body is Player:
		var error = get_tree().reload_current_scene()
		if error != 0:
			print("Error reloading scene:", error)
