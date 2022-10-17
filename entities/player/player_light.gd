extends Light2D


func _ready():
	var error = Game.connect("player_light_changed", self, "_on_change")
	assert(error == 0, "Error connecting player_light_changed: " + str(error))


func _on_change(_energy: float):
	energy = _energy
