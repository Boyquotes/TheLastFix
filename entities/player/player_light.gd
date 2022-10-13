extends Light2D


func _ready():
	var error = Game.connect("player_light_changed", self, "_on_change")
	if error != 0:
		print("Error connecting player_light_changed: ", error)


func _on_change(_energy: float):
	energy = _energy
